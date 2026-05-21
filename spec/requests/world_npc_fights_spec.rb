# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World NPC fights", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Starter Plains") }
  let(:character) { create(:character, user:, level: 3, current_hp: 100, max_hp: 100) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:npc_template) do
    create(:npc_template,
      npc_key: "captured_bandit",
      name: "Captured Bandit",
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
      "npc_name" => "Captured Bandit"
    )
    expect(match.arena_participations.find_by(character:)).to be_present
    expect(match.arena_participations.find_by(npc_template:)).to be_present
    expect(match.combat_log_entries.map(&:message)).to include("The fight begins!")
    expect(action_offer.reload).to be_completed
  end

  it "rejects stale or mismatched action keys" do
    post world_npc_fights_path, params: {tile_npc_id: tile_npc.id, action_key: "missing"}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
    expect(action_offer.reload).to be_offered
  end
end
