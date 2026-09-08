# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Airship travel", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character, level: 10) }
  let(:source) { create(:zone, :city_node, name: "Outpost Residential Quarter") }
  let(:destination) { create(:zone, :city, name: "Fixture Arrival Station") }
  let(:region) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone: source, x: 5, y: 5) }
  let!(:source_station) do
    create(:city_hotspot, :read_only_city_building, zone: source, key: "airship_station",
      action_params: {"feature" => "airship_station"})
  end
  let!(:destination_station) do
    create(:city_hotspot, :read_only_city_building, zone: destination, key: "airship_station",
      action_params: {"feature" => "airship_station"})
  end
  let(:departure) { Time.current + 10.minutes }

  before do
    sign_in character.user, scope: :user
    character.user.currency_wallet.update!(nv_balance: 500)
  end

  it "shows the three captured Forpost fares unavailable until complete destinations and schedules exist" do
    get city_building_path("airship_station")

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("h1").text).to eq("Forpost Airship Station")
    expect(document.css("[data-airship-route] td:first-child").map(&:text)).to eq(["Forpost - Khalgan Fair", "Forpost - Telior Island", "Forpost - Oktal"])
    expect(document.css("[data-airship-route] td:nth-child(2)").map(&:text)).to eq(["350.00 NV", "150.00 NV", "150.00 NV"])
    expect(document.css(".nl-airship-station button[disabled]").size).to eq(3)
    expect(document.css(".nl-airship-station form")).to be_empty
    expect(WorldActionOffer.where(character:, action_type: "board_airship")).to be_empty
    expect(character.user.currency_wallet.reload.balance).to eq(500)
  end

  it "boards from an owned station offer once and renders the persisted waiting map and deadline" do
    freeze_time do
      configure_flight
      get city_building_path("airship_station")
      action_key = Nokogiri::HTML(response.body).at_css(".nl-airship-station input[name=action_key]")["value"]

      2.times { post airship_path, params: {action_key:, fare_nv: 1, destination_zone_id: source.id} }

      expect(response).to redirect_to(airship_path)
      journey = AirshipJourney.sole
      expect(journey).to have_attributes(fare_nv: 150, destination_zone: destination)
      expect(character.user.currency_wallet.reload.balance).to eq(350)
      get airship_path

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.css(".nl-airship-tile").size).to eq(21)
      expect(document.at_css(".nl-airship-timer").text).to eq("00:10:00")
      expect(document.at_css(".nl-airship-page")["data-nl-airship-deadline-value"]).to eq(departure.iso8601(6))
      expect(document.at_css(".nl-airship-actions form")["data-turbo-confirm"]).to include("will not be refunded")
      expect(document.css(".nl-top-nav").text).to include("Your character", "Inventory")
      expect(document.css(".nl-top-nav").text).not_to include("Return", "City")
      expect(document.at_css("meta[name=turbo-cache-control]")["content"]).to eq("no-cache")
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  it "renders the destination's authored station label as escaped text without inheriting Forpost's label" do
    title = "Destination Airship Station <script>alert(1)</script>"
    destination.update!(metadata: {"airship_station_title" => title})
    position.update!(zone: destination)

    get city_building_path("airship_station")

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css("h1").text).to eq(title)
    expect(document.at_css(".nl-location-text").text).to eq("#{title} [ 1 ]")
    expect(document.css("h1 script, .nl-location-text script")).to be_empty
    expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    expect(response.body).not_to include("Forpost Airship Station")
    expect(Game::World::CityBuildingCatalog.fetch("airship_station", zone: source).fetch("title"))
      .to eq("Forpost Airship Station")
  end

  it "returns bounded flight snapshots from server time and keeps arrival aboard until explicit disembarkation" do
    freeze_time do
      journey = board_flight
      travel_to(departure + 30.seconds)
      get airship_path(format: :json), params: {center_x: 900, phase: "arrived"}
      snapshot = response.parsed_body
      expect(snapshot).to include("phase" => "in_flight", "center_x" => 13.0, "center_y" => 13.0)
      expect(Nokogiri::HTML.fragment(snapshot.fetch("map_html")).css(".nl-airship-tile").size).to eq(55)
      expect(snapshot.fetch("velocity_x")).to eq(0.1)
      expect(position.reload).to have_attributes(zone: region, x: 13, y: 13)
      post disembark_airship_path, params: {journey_id: journey.id}
      expect(response).to redirect_to(airship_path)
      expect(journey.reload).to be_aboard

      travel_to(journey.arrives_at)
      get airship_path
      document = Nokogiri::HTML(response.body)
      expect(document.css(".nl-airship-tile").size).to eq(21)
      expect(document.css(".nl-airship-timer")).to be_empty
      expect(document.at_css(".nl-airship-actions form")["data-turbo-confirm"]).to be_nil
      expect(journey.reload).to be_aboard

      2.times { post disembark_airship_path, params: {journey_id: journey.id} }
      expect(response).to redirect_to(city_building_path("airship_station"))
      expect(journey.reload).to be_disembarked
      expect(position.reload).to have_attributes(zone: destination, x: 0, y: 0)
      expect(character.user.currency_wallet.reload.balance).to eq(350)
    end
  end

  it "cancels a waiting flight at its boarding station without refund and rejects another owner's journey" do
    freeze_time do
      journey = board_flight
      foreign = create(:airship_journey)
      post disembark_airship_path, params: {journey_id: foreign.id}
      expect(journey.reload).to be_aboard
      expect(foreign.reload).to be_aboard

      post disembark_airship_path, params: {journey_id: journey.id}
      expect(response).to redirect_to(city_building_path("airship_station"))
      expect(journey.reload).to be_cancelled
      expect(position.reload).to have_attributes(zone: source, x: 5, y: 5)
      expect(character.user.currency_wallet.reload.balance).to eq(350)
    end
  end

  it "rejects a forged boarding key and unauthenticated travel without creating a paid reservation" do
    post airship_path, params: {action_key: "forged"}
    expect(response).to redirect_to(world_path)
    sign_out character.user
    post airship_path, params: {action_key: "forged"}
    expect(response).to redirect_to(new_user_session_path)
    expect(AirshipJourney.count).to eq(0)
    expect(character.user.currency_wallet.reload.balance).to eq(500)
  end

  def configure_flight
    catalog = Game::World::AirshipRoutes.new(config: {
      "fixture_flight" => {
        "source_zone" => source.name, "destination_zone" => destination.name,
        "destination_x" => 0, "destination_y" => 0,
        "label" => "Fixture Destination", "route_label" => "Fixture Airship Route", "fare_nv" => 150,
        "departures" => [departure.iso8601(6)], "duration_seconds" => 120,
        "waypoints" => [
          {"offset_seconds" => 0, "zone" => region.name, "x" => 10, "y" => 10},
          {"offset_seconds" => 120, "zone" => region.name, "x" => 22, "y" => 22}
        ]
      }
    })
    allow(Game::World::AirshipRoutes).to receive(:new).and_return(catalog)
  end

  def board_flight
    configure_flight
    get city_building_path("airship_station")
    action_key = Nokogiri::HTML(response.body).at_css(".nl-airship-station input[name=action_key]")["value"]
    post airship_path, params: {action_key:}
    AirshipJourney.sole
  end
end
