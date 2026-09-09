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

  context "with the captured eastern gate" do
    let(:gate_definition) { Game::World::CityCatalog::GATES.fetch("east") }
    let(:law) do
      create(
        :zone,
        :city,
        name: "Law Quarter",
        metadata: {"city_key" => "forpost", "city_node_key" => gate_definition.fetch("node_key"), "title" => "Law Quarter"}
      )
    end
    let!(:east_exit) do
      x, y = gate_definition.fetch("local_coordinates")
      create(
        :city_hotspot,
        :city_gate,
        zone: law,
        destination_zone: outdoors,
        key: "east_gate",
        name: gate_definition.fetch("name"),
        action_params: {"destination_x" => x, "destination_y" => y}
      )
    end
    let!(:east_entrance) do
      x, y = gate_definition.fetch("local_coordinates")
      create(
        :tile_building,
        zone: outdoors.name,
        x:,
        y:,
        building_key: "outpost_east_gate",
        name: gate_definition.fetch("name"),
        destination_zone: law,
        destination_x: 0,
        destination_y: 0,
        required_level: 0,
        metadata: {"presence_label" => gate_definition.fetch("presence_label")}
      )
    end

    before { position.update!(zone: law, x: 0, y: 0) }

    it "lets a level-zero character leave and re-enter the same Law Quarter through its gate" do
      character.update!(level: 0)
      get world_path
      expect(response.body).to include('data-hotspot-key="east_gate"')
      expect(response.body).not_to include('data-landmark-key="city_exit"')
      exit_offer = WorldActionOffer.offered.find_by!(character:, target: east_exit)

      post interact_hotspot_world_path,
        params: {hotspot_id: east_exit.id, action_key: exit_offer.action_key}

      expect(response).to redirect_to(world_path)
      expect(position.reload).to have_attributes(zone: outdoors, x: 11, y: 9)
      expect(exit_offer.reload).to be_completed
      expect(MovementCommand.moving.where(character:)).to be_empty

      follow_redirect!
      expect(response.body).to include("Outpost, East Gate")
      entry_offer = WorldActionOffer.offered.find_by!(character:, target: east_entrance)
      entry_params = {building_id: east_entrance.id, action_key: entry_offer.action_key}
      post enter_building_world_path, params: entry_params

      expect(response).to redirect_to(world_path)
      expect(position.reload).to have_attributes(zone: law, x: 0, y: 0)
      expect(entry_offer.reload).to be_completed
      expect(MovementCommand.moving.where(character:)).to be_empty
      follow_redirect!
      expect(response.body).to include('aria-label="Law Quarter city map"')

      post enter_building_world_path, params: entry_params

      expect(position.reload).to have_attributes(zone: law, x: 0, y: 0)
      expect(entry_offer.reload).to be_completed
    end

    it "rejects an eastern entrance offer after the character leaves its exact cell" do
      position.update!(zone: outdoors, x: 11, y: 9)
      get world_path
      offer = WorldActionOffer.offered.find_by!(character:, target: east_entrance)
      position.update!(x: 12, y: 10)

      post enter_building_world_path,
        params: {building_id: east_entrance.id, action_key: offer.action_key}

      expect(response).to redirect_to(world_path)
      expect(position.reload).to have_attributes(zone: outdoors, x: 12, y: 10)
      expect(offer.reload).not_to be_completed
    end
  end

  it "keeps a visible route usable after another read of the same city node" do
    get world_path
    first_offer = WorldActionOffer.offered.find_by!(character:, target: to_business)

    get world_path

    expect(first_offer.reload).to be_offered
    expect(WorldActionOffer.offered.find_by!(character:, target: to_business)).to eq(first_offer)

    post interact_hotspot_world_path,
      params: {hotspot_id: to_business.id, action_key: first_offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(position.reload.zone).to eq(business)
    expect(first_offer.reload).to be_completed
  end

  it "does not reactivate a consumed building key when its city is read again" do
    shop = create(:city_hotspot, :shop, zone: central)
    get world_path
    first_offer = WorldActionOffer.offered.find_by!(character:, target: shop)
    action = {hotspot_id: shop.id, action_key: first_offer.action_key}
    post interact_hotspot_world_path, params: action
    expect(response).to redirect_to(shop_path)

    get world_path
    next_offer = WorldActionOffer.offered.find_by!(character:, target: shop)
    expect(next_offer).not_to eq(first_offer)
    post interact_hotspot_world_path, params: action

    expect(response).to redirect_to(world_path)
    expect(flash[:alert]).to eq("Action offer is no longer available")
    expect(first_offer.reload).to be_completed
    expect(next_offer.reload).to be_offered
    expect(position.reload).to have_attributes(zone: central, x: 5, y: 5)
  end

  it "rejects a visible building whose availability changed before entry" do
    shop = create(:city_hotspot, :shop, zone: central)
    get world_path
    offer = WorldActionOffer.offered.find_by!(character:, target: shop)
    shop.update!(active: false)

    post interact_hotspot_world_path, params: {hotspot_id: shop.id, action_key: offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(flash[:alert]).to eq("Location is currently unavailable.")
    expect(position.reload).to have_attributes(zone: central, x: 5, y: 5)
    expect(offer.reload).to be_failed
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
