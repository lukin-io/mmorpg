# frozen_string_literal: true

require "rails_helper"
require "timeout"

# js metadata uses the existing truncation strategy so separate PostgreSQL
# connections can see committed setup; this remains a non-browser request spec.
RSpec.describe "Airship boarding versus Arena application reads", type: :request, js: true do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city) }
  let(:destination) { create(:zone, :city) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: city) }
  let!(:arena) { create(:city_hotspot, :arena, zone: city) }
  let!(:station) { create(:city_hotspot, zone: city, action_params: {feature: "airship_station"}) }
  let!(:destination_station) { create(:city_hotspot, zone: destination, action_params: {feature: "airship_station"}) }
  let(:room) { create(:arena_room, zone: city, level_min: 0, level_max: 33) }
  let(:routes) do
    Game::World::AirshipRoutes.new(config: {
      "source_destination" => {
        "source_zone" => city.name, "destination_zone" => destination.name,
        "destination_x" => 0, "destination_y" => 0,
        "label" => "Destination", "route_label" => "Route Source - Destination", "fare_nv" => 150,
        "departures" => [10.minutes.from_now.iso8601(6)], "duration_seconds" => 240,
        "waypoints" => [
          {"offset_seconds" => 0, "zone" => region.name, "x" => 5, "y" => 5},
          {"offset_seconds" => 240, "zone" => region.name, "x" => 9, "y" => 9}
        ]
      }
    })
  end

  def authenticated_client
    ActionDispatch::Integration::Session.new(Rails.application).tap do |client|
      client.post user_session_path, params: {user: {email: character.user.email, password: "Password123!"}}
      expect(client.response).to have_http_status(:redirect)
    end
  end

  def wait_for_postgres_lock(pid)
    Timeout.timeout(5) do
      loop do
        waiting = ActiveRecord::Base.connection.select_value(
          "SELECT wait_event_type FROM pg_stat_activity WHERE pid = #{Integer(pid)}"
        )
        break if waiting == "Lock"
        Thread.pass
      end
    end
  end

  it "finishes the authorized list read before boarding and denies later ground-list reads" do
    applicant = create(:character, name: "GroundApplicant", level: 10)
    create(:character_position, character: applicant, zone: city)
    create(:arena_application, arena_room: room, applicant:)
    character.remember_gameplay_context!(name: "arena_room", params: {room_id: room.id})
    character.user.currency_wallet.update!(nv_balance: 500)
    authored_routes = routes
    allow(Game::World::AirshipRoutes).to receive(:new).and_return(authored_routes)
    key = Game::World::AirshipTravel.new(character:, routes: authored_routes).station_routes!.sole.action_key
    read_client = authenticated_client
    board_client = authenticated_client
    checked = Queue.new
    release_read = Queue.new
    board_connection = Queue.new
    errors = Queue.new
    workers = []

    allow_any_instance_of(ArenaApplicationsController).to receive(:ensure_room_access!).and_wrap_original do |original|
      original.call
      checked << true
      release_read.pop
    end

    workers << Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        read_client.get arena_room_arena_applications_path(room), as: :json
      end
    rescue => error
      errors << error
    end
    Timeout.timeout(5) { checked.pop }

    workers << Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        board_connection << connection.select_value("SELECT pg_backend_pid()")
        board_client.post airship_path, params: {action_key: key}
      end
    rescue => error
      errors << error
    end
    wait_for_postgres_lock(Timeout.timeout(5) { board_connection.pop })
    expect(AirshipJourney.where(character:)).to be_empty
    release_read << true
    workers.each { |worker| expect(worker.join(10)).to eq(worker) }
    raise errors.pop unless errors.empty?

    expect(read_client.response).to have_http_status(:ok)
    expect(read_client.response.parsed_body.pluck("applicant").pluck("name")).to include("GroundApplicant")
    expect(board_client.response).to have_http_status(:see_other)
    expect(board_client.response.location).to end_with(airship_path)
    expect(AirshipJourney.aboard.where(character:).count).to eq(1)
    expect(character.user.currency_wallet.reload.nv_balance).to eq(350)

    read_client.get arena_room_arena_applications_path(room), as: :json
    expect(read_client.response).to have_http_status(:conflict)
    expect(read_client.response.body).not_to include("GroundApplicant")
  ensure
    release_read << true if release_read
    workers&.each do |worker|
      worker.join(10)
      worker.kill if worker.alive?
    end
  end
end
