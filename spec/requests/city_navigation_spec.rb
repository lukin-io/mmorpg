# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City navigation", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:central) { create(:zone, :city_node, name: "Central Square") }
  let(:business) do
    create(
      :zone,
      :city,
      name: "Business Quarter",
      metadata: {"city_key" => "forpost", "city_node_key" => "forpost3", "title" => "Business Quarter"}
    )
  end
  let(:outdoors) { create(:zone, :mvp_outdoor_region, name: "Forpost Region") }
  let!(:position) { create(:character_position, character:, zone: central, x: 5, y: 5) }
  let!(:to_business) do
    create(
      :city_hotspot,
      :district,
      zone: central,
      destination_zone: business,
      key: "go_forpost3",
      name: "Business Quarter"
    )
  end
  let!(:west_gate) do
    create(
      :city_hotspot,
      :city_gate,
      zone: central,
      destination_zone: outdoors,
      key: "west_gate",
      name: "West Gate",
      action_params: {"destination_x" => 7, "destination_y" => 0}
    )
  end
  let!(:arena) { create(:city_hotspot, :arena, zone: central, required_level: 0) }

  before { sign_in user, scope: :user }

  it "renders fresh current-node action keys without wilderness movement" do
    get world_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Central Square", "Business Quarter", "West Gate", "Arena")
    expect(response.body).to include('name="action_key"')
    expect(response.body).to include("nl-city-scene-image", "nl-city-hotspots")
    expect(response.body).not_to include("city-hitbox", "Observed landmarks")
    expect(WorldActionOffer.offered.where(character:).pluck(:action_type)).to contain_exactly(
      "city_transition",
      "enter_city_building",
      "exit_city"
    )
    expect(MovementCommand.where(character:)).to be_empty
  end

  it "offers ordinary navigation and the observed starter-accessible Arena" do
    character.update!(level: 0)

    get world_path

    expect(response).to have_http_status(:success)
    expect(WorldActionOffer.offered.where(character:, target: to_business)).to exist
    expect(WorldActionOffer.offered.where(character:, target: west_gate)).to exist
    expect(WorldActionOffer.offered.where(character:, target: arena)).to exist
  end

  it "moves immediately to the selected city node and completes its offer" do
    get world_path
    offer = WorldActionOffer.offered.find_by!(character:, target: to_business)

    post interact_hotspot_world_path,
      params: {hotspot_id: to_business.id, action_key: offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(position.reload).to have_attributes(zone: business, x: 0, y: 0)
    expect(offer.reload).to be_completed
    expect(MovementCommand.where(character:)).to be_empty
  end

  it "enters a documented building with its current-node offer" do
    position.update!(zone: business)
    market = create(:city_hotspot, :read_only_city_building, zone: business)
    get world_path
    offer = WorldActionOffer.offered.find_by!(character:, target: market)

    post interact_hotspot_world_path,
      params: {hotspot_id: market.id, action_key: offer.action_key}

    expect(response).to redirect_to(city_building_path("market"))
    expect(offer.reload).to be_completed
    expect(position.reload).to have_attributes(zone: business, x: 5, y: 5)
  end

  it "returns through the exact West Gate cell" do
    get world_path
    offer = WorldActionOffer.offered.find_by!(character:, target: west_gate)

    post interact_hotspot_world_path,
      params: {hotspot_id: west_gate.id, action_key: offer.action_key}

    expect(position.reload).to have_attributes(zone: outdoors, x: 7, y: 0)
    expect(offer.reload).to be_completed
  end

  it "rotates outgoing offers whenever the city node refreshes" do
    get world_path
    first_offer = WorldActionOffer.offered.find_by!(character:, target: to_business)

    get world_path

    expect(first_offer.reload).to be_cancelled
    expect(WorldActionOffer.offered.find_by!(character:, target: to_business).action_key).not_to eq(first_offer.action_key)
  end

  it "rejects missing, expired, mismatched, and wrong-node offers" do
    post interact_hotspot_world_path, params: {hotspot_id: to_business.id, action_key: nil}
    expect(position.reload.zone).to eq(central)

    expired = create(
      :world_action_offer,
      :expired,
      character:,
      zone: central,
      x: 5,
      y: 5,
      action_type: "city_transition",
      target: to_business
    )
    post interact_hotspot_world_path, params: {hotspot_id: to_business.id, action_key: expired.action_key}
    expect(position.reload.zone).to eq(central)

    mismatched = create(
      :world_action_offer,
      character:,
      zone: central,
      x: 5,
      y: 5,
      action_type: "exit_city",
      target: west_gate
    )
    post interact_hotspot_world_path, params: {hotspot_id: to_business.id, action_key: mismatched.action_key}
    expect(position.reload.zone).to eq(central)

    position.update!(zone: business)
    post interact_hotspot_world_path, params: {hotspot_id: to_business.id, action_key: mismatched.action_key}
    expect(position.reload.zone).to eq(business)
  end

  it "forbids another character's city offer" do
    other_user = create(:user)
    other_character = create(:character, user: other_user)
    create(:character_position, character: other_character, zone: central, x: 5, y: 5)
    foreign_offer = create(
      :world_action_offer,
      character: other_character,
      zone: central,
      x: 5,
      y: 5,
      action_type: "city_transition",
      target: to_business
    )

    post interact_hotspot_world_path,
      params: {hotspot_id: to_business.id, action_key: foreign_offer.action_key}

    expect(response).to redirect_to(root_path)
    expect(position.reload.zone).to eq(central)
    expect(foreign_offer.reload).to be_offered
  end

  it "requires authentication" do
    sign_out user

    get world_path

    expect(response).to redirect_to(new_user_session_path)
    expect(WorldActionOffer.where(character:)).to be_empty
  end
end
