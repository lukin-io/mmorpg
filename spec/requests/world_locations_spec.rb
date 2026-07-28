# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open-world locations", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region, name: "Location Test Region") }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }
  let!(:building) do
    create(
      :tile_building,
      :world_location,
      zone: zone.name,
      x: 4,
      y: 6,
      building_key: "frontier_village"
    )
  end

  before do
    sign_in user, scope: :user
  end

  it "requires an authenticated playable character" do
    sign_out user

    get world_location_path("frontier_village")

    expect(response).to redirect_to(new_user_session_path)
  end

  it "enters from the server-offered world-cell action without moving coordinates" do
    get world_path
    offer = WorldActionOffer.offered.find_by!(character:, action_type: "enter_building", target: building)

    post enter_building_world_path, params: {
      building_id: building.id,
      action_key: offer.action_key
    }

    expect(response).to redirect_to(world_location_path("frontier_village"))
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "renders the fixed CSS scene and server-offered linked hotspots" do
    get world_location_path("frontier_village")

    expect(response).to have_http_status(:success)
    expect(response.body).to include("nl-world-location-scene--village")
    expect(response.body).to include("Trading Post", "Leave the village")
    expect(WorldActionOffer.offered.where(character:, action_type: "open_location_feature").count).to eq(2)
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "accepts the short-lived shop hotspot offer" do
    get world_location_path("frontier_village")
    offer = WorldActionOffer.offered.where(character:).find { |candidate| candidate.metadata["feature"] == "shop" }

    post world_location_feature_path("frontier_village"), params: {
      feature_key: "trading_post",
      action_key: offer.action_key
    }

    expect(response).to redirect_to(shop_path)
    expect(offer.reload).to be_completed
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "returns to the same persisted world cell through the exit hotspot" do
    get world_location_path("frontier_village")
    offer = WorldActionOffer.offered.where(character:).find { |candidate| candidate.metadata["hotspot_key"] == "exit" }

    post world_location_feature_path("frontier_village"), params: {
      feature_key: "exit",
      action_key: offer.action_key
    }

    expect(response).to redirect_to(world_path)
    expect(offer.reload).to be_completed
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "rejects a persisted feature key that does not match its owned offer" do
    get world_location_path("frontier_village")
    offer = WorldActionOffer.offered.where(character:).find { |candidate| candidate.metadata["feature"] == "shop" }

    post world_location_feature_path("frontier_village"), params: {
      feature_key: "exit",
      action_key: offer.action_key
    }

    expect(response).to redirect_to(world_location_path("frontier_village"))
    expect(offer.reload).to be_failed
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end

  it "rejects an old feature offer after the persisted coordinate changes" do
    get world_location_path("frontier_village")
    offer = WorldActionOffer.offered.where(character:).find { |candidate| candidate.metadata["feature"] == "shop" }
    position.update!(x: 5)

    post world_location_feature_path("frontier_village"), params: {
      feature_key: "trading_post",
      action_key: offer.action_key
    }

    expect(response).to redirect_to(world_path)
    expect(offer.reload).to be_offered
    expect(position.reload).to have_attributes(zone:, x: 5, y: 6)
  end

  it "rejects stale location access after the persisted coordinate changes" do
    position.update!(x: 5)

    get world_location_path("frontier_village")

    expect(response).to redirect_to(world_path)
  end

  it "renders replacement feature content directly from the persisted building row" do
    metadata = building.metadata.deep_dup
    metadata["location"]["features"][0]["label"] = "Quartermaster"
    building.update!(metadata:)

    get world_location_path(building.location_key)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Quartermaster")
    expect(response.body).not_to include("Trading Post")
  end

  it "stops exposing the location immediately when its existing cell record is moved" do
    building.update!(x: 5)

    get world_location_path(building.location_key)

    expect(response).to redirect_to(world_path)
    expect(position.reload).to have_attributes(zone:, x: 4, y: 6)
  end
end
