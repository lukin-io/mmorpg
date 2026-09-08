# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Airship navigation isolation", type: :request do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city) }
  let!(:position) { create(:character_position, character:, zone: city, x: 0, y: 0) }
  let!(:journey) { create(:airship_journey, character:, source_zone: city) }

  before { sign_in character.user, scope: :user }

  it "restores the active journey even if a saved surface was replaced in another tab" do
    character.remember_gameplay_context!(name: "world")

    get world_path

    expect(response).to redirect_to(airship_path)
    expect(character.reload.position).to have_attributes(zone_id: city.id, x: 0, y: 0)
    expect(Game::World::ResumeContext.new(character:).resume_path).to eq(airship_path)
  end

  it "rejects ground navigation and mutation URLs while preserving position and the journey" do
    [city_building_path("airship_station"), shop_path, arena_index_path].each do |path|
      get path
      expect(response).to redirect_to(airship_path)
    end

    post move_world_path, params: {target_x: 1, target_y: 0, action_key: "forged"}
    expect(response).to redirect_to(airship_path)
    expect(MovementCommand.moving.where(character:)).to be_empty
    expect(journey.reload).to be_aboard
    expect(position.reload).to have_attributes(zone_id: city.id, x: 0, y: 0)
  end

  it "keeps Inventory and Character accessible and returns them to the flight" do
    [inventory_path, stats_character_path(character)].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('href="/airship"')
      expect(response.body).not_to include('class="nl-city-view"')
    end
    expect(journey.reload).to be_aboard
  end

  it "permits the route roster refresh without redirecting it to ground gameplay" do
    get players_world_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(journey.route_label)
    expect(response.body).not_to include("nl-map-viewport")
  end

  it "does not let a stale encounter poll summon a ground NPC aboard" do
    post world_encounter_check_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("interrupted" => false)
    expect(ArenaMatch.count).to eq(0)
    expect(journey.reload).to be_aboard
  end
end
