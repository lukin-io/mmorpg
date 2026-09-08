# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::Presence, "aboard an airship" do
  include ActiveSupport::Testing::TimeHelpers

  let(:station) { create(:zone, :city) }
  let(:destination) { create(:zone, :city) }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let(:character) { create(:character, name: "FlightViewer") }
  let!(:position) { create(:character_position, character:, zone: station) }
  let!(:session) { create(:user_session, user: character.user) }
  let(:departure) { 1.minute.from_now }
  let!(:journey) { board(character) }

  before { freeze_time }
  after { travel_back }

  def board(passenger, **attributes)
    create(:airship_journey, character: passenger, source_zone: station,
      destination_zone: destination, flight_region: region,
      route_key: "forpost_oktal", departs_at: departure, **attributes)
  end

  def neighbor(name:, zone: station, user: nil)
    create(:character, name:, **(user ? {user:} : {})).tap do |other|
      create(:character_position, character: other, zone:)
      create(:user_session, user: other.user)
    end
  end

  it "shares one flight audience and chat key across waiting, flight, and arrival in different cells" do
    passenger = neighbor(name: "OtherPassenger", zone: region)
    board(passenger)
    key = "airship:#{journey.flight_key}"

    [journey.departs_at - 1.second, journey.departs_at, journey.arrives_at].each do |at|
      travel_to(at)
      UserSession.update_all(last_seen_at: Time.current)
      position.update!(zone: at < journey.departs_at ? station : region, x: 7, y: 7)

      presence = described_class.new(character:)
      expect(presence.context_key).to eq(key)
      expect(described_class.new(character: passenger).context_key).to eq(key)
      expect(presence.call).to have_attributes(label: "Route Forpost - Oktal", count: 2)
      expect(presence.call.players).to contain_exactly(character, passenger)
    end
  end

  it "excludes ground players, other routes, other departures, and ended reservations" do
    passenger = neighbor(name: "SameFlight")
    board(passenger)
    neighbor(name: "GroundNeighbor")
    board(neighbor(name: "OtherRoute"), route_key: "forpost_fair")
    board(neighbor(name: "LaterFlight"), departs_at: departure + 1.hour)
    board(neighbor(name: "Disembarked"), status: :disembarked)
    board(neighbor(name: "Cancelled"), status: :cancelled)

    expect(described_class.new(character:).call.players).to contain_exactly(character, passenger)
  end

  it "excludes aboard characters from the station and from ground cells along the path" do
    ground = neighbor(name: "StationObserver")
    expect(described_class.new(character: ground).call.players).to contain_exactly(ground)

    position.update!(zone: region, x: 5, y: 5)
    ground.position.update!(zone: region, x: 5, y: 5)
    expect(described_class.new(character: ground).call.players).to contain_exactly(ground)

    journey.update!(status: :disembarked, disembarked_at: Time.current)
    expect(described_class.new(character: ground).call.players).to contain_exactly(character, ground)
  end

  it "retains online-session and selected-character filtering with ten sorted rows and a full count" do
    11.times do |number|
      board(neighbor(name: "A#{number.to_s.rjust(2, '0')}"))
    end
    create(:user_session, user: character.user)
    expired = neighbor(name: "ExpiredPassenger")
    board(expired)
    expired.user.user_sessions.update_all(last_seen_at: 5.minutes.ago)
    signed_out = neighbor(name: "SignedOutPassenger")
    board(signed_out)
    signed_out.user.user_sessions.update_all(signed_out_at: Time.current)
    alternate = neighbor(name: "InactiveAlternate", user: character.user)
    board(alternate)

    result = described_class.new(character:, sort: "untrusted").call
    expect(result.count).to eq(12)
    expect(result.players.map(&:name)).to eq((0..9).map { |number| "A#{number.to_s.rjust(2, '0')}" })
  end

  it "does not read ground content or room candidates while resolving an aboard audience" do
    sql = []
    callback = ->(_name, _start, _finish, _id, payload) { sql << payload[:sql] }
    result = nil
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      presence = described_class.new(character:)
      presence.context_key
      result = presence.call
    end

    expect(result.count).to eq(1)
    expect(sql.join(" ")).not_to match(/\b(?:tile_npcs|tile_buildings|map_tile_templates|city_hotspots|arena_rooms)\b/i)
    expect(sql.count { |statement| statement.match?(/\ASELECT "airship_journeys"\.\* FROM "airship_journeys".*LIMIT/i) }).to eq(1)
  end
end
