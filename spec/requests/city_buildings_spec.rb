# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City buildings", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:zone, :city_node, name: "Trading Quarter") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: city) }

  before { sign_in user, scope: :user }

  it "renders the captured Market without economic mutation controls" do
    get city_building_path("market")

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Market", "Newspaper display", "Huge", "1,500 NV")
    expect(response.body).to include("read-only")
    expect(response.body).not_to include("Rent stall", "Buy listing")
  end

  it "renders the captured service-specific read-only surfaces" do
    {
      "junk_dealer" => ["Junk Dealer", "Stock was not captured"],
      "numismatics" => ["Numismatics Shop", "Ancient Alvian Coin"],
      "airship_station" => ["Oktal Airship Station", "Khalgan Fair", "200 NV"],
      "hospital" => ["Hospital", "Beginner healer bag", "Pharmacy"]
    }.each do |building_key, expected_text|
      market.update!(key: building_key, name: expected_text.first, action_params: {"feature" => building_key})

      get city_building_path(building_key)

      expect(response).to have_http_status(:success)
      expected_text.each { |text| expect(response.body).to include(text) }
    end
  end

  it "persists the exact building as the login resume context" do
    get city_building_path("market")

    expect(character.reload.gameplay_context).to eq(
      "name" => "city_building",
      "params" => {"building_key" => "market"}
    )
  end

  it "rejects unsupported, inactive, wrong-node, and outdoor access" do
    get city_building_path("bank")
    expect(response).to redirect_to(world_path)

    market.update!(active: false)
    get city_building_path("market")
    expect(response).to redirect_to(world_path)

    market.update!(active: true)
    position.update!(zone: create(:zone, :city, name: "Other City Node"))
    get city_building_path("market")
    expect(response).to redirect_to(world_path)

    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 0)
    get city_building_path("market")
    expect(response).to redirect_to(world_path)
  end

  it "requires authentication and does not persist building context" do
    sign_out user

    get city_building_path("market")

    expect(response).to redirect_to(new_user_session_path)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
  end
end
