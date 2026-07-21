# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World NPC fights", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Outpost Surroundings") }
  let(:character) { create(:character, user:, level: 3, current_hp: 100, max_hp: 100) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:npc_template) do
    create(:npc_template,
      npc_key: "plague_rat",
      name: "Plague Rat",
      role: "hostile",
      level: 2,
      metadata: {"health" => 40, "base_damage" => 4})
  end
  let!(:tile_npc) do
    create(:tile_npc,
      npc_template:,
      zone: zone.name,
      x: position.x,
      y: position.y,
      npc_key: npc_template.npc_key,
      npc_role: "hostile",
      current_hp: 40,
      max_hp: 40)
  end
  let!(:action_offer) do
    create(:world_action_offer,
      character:,
      zone:,
      x: position.x,
      y: position.y,
      action_type: "attack_npc",
      target: tile_npc)
  end

  before do
    sign_in user, scope: :user
  end

  it "starts a hostile NPC fight through ArenaMatch" do
    expect {
      post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: action_offer.action_key}
    }.to change(ArenaMatch, :count).by(1)
      .and change(ArenaParticipation, :count).by(2)

    match = ArenaMatch.last
    expect(response).to redirect_to(arena_match_path(match))
    expect(match).to be_live
    expect(match.metadata).to include(
      "source" => "world_npc",
      "tile_npc_id" => tile_npc.id,
      "npc_template_id" => npc_template.id,
      "npc_name" => "Plague Rat"
    )
    expect(match.arena_participations.find_by(character:)).to be_present
    expect(match.arena_participations.find_by(npc_template:)).to be_present
    expect(match.combat_log_entries.map(&:message)).to include("The fight begins!")
    expect(action_offer.reload).to be_completed
  end

  it "returns the existing JSON contract without requiring Swagger support" do
    post world_npc_fights_path,
      params: {tile_npc_id: tile_npc.id, action_key: action_offer.action_key},
      as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include(
      "success" => true,
      "match_id" => ArenaMatch.last.id,
      "redirect_url" => arena_match_path(ArenaMatch.last)
    )
    expect(action_offer.reload).to be_completed
  end

  it "rejects stale or mismatched action keys" do
    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: "missing"}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end

  it "forbids another character's world action offer" do
    other_user = create(:user)
    other_character = create(:character, user: other_user)
    other_offer = create(
      :world_action_offer,
      character: other_character,
      zone:,
      x: position.x,
      y: position.y,
      action_type: "attack_npc",
      target: tile_npc
    )

    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: other_offer.action_key}

    expect(response).to redirect_to(root_path)
    expect(ArenaMatch.count).to eq(0)
    expect(other_offer.reload).to be_offered
  end

  it "returns forbidden JSON for another character's offer" do
    other_character = create(:character)
    other_offer = create(
      :world_action_offer,
      character: other_character,
      zone:,
      x: position.x,
      y: position.y,
      action_type: "attack_npc",
      target: tile_npc
    )

    post world_npc_fights_path,
      params: {tile_npc_id: tile_npc.id, action_key: other_offer.action_key},
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body).to eq("error" => "forbidden")
    expect(ArenaMatch.count).to eq(0)
    expect(other_offer.reload).to be_offered
  end

  it "rolls the accepted offer back when the NPC is no longer on the current cell" do
    tile_npc.update!(x: position.x + 1)

    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: action_offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end

  it "rejects a defeated NPC without consuming its offer" do
    tile_npc.update!(current_hp: 0, defeated_at: Time.current)

    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: action_offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end

  it "rejects a null NPC id without consuming its offer" do
    post world_npc_fights_path, params: {tile_npc_id: nil, action_key: action_offer.action_key}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end

  it "requires authentication" do
    sign_out user

    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: action_offer.action_key}

    expect(response).to redirect_to(new_user_session_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end
end
