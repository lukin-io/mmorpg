# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World context actions", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, name: "ContextWalker") }
  let(:zone) { create(:zone, name: "Context Woods", location_type: "outdoor") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "continues to the allowlisted profile when no NPC interrupts" do
    post world_context_action_path, params: {context: "profile"}

    expect(response).to redirect_to(player_path(name: character.name))
    expect(ArenaMatch.count).to eq(0)
  end

  it "persists inventory as the post-fight destination when an NPC interrupts" do
    create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)

    expect {
      post world_context_action_path, params: {context: "inventory"}
    }.to change(ArenaMatch, :count).by(1)
      .and change(ArenaParticipation, :count).by(3)

    match = ArenaMatch.last
    expect(response).to redirect_to(arena_match_path(match))
    expect(match.metadata["return_context"]).to eq("name" => "inventory")
  end

  it "rejects an arbitrary return destination without starting combat" do
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    post world_context_action_path, params: {context: "https://example.test"}

    expect(response).to redirect_to(world_path)
    expect(ArenaMatch.count).to eq(0)
  end

  it "does not start a wilderness fight for a city position" do
    zone.update!(location_type: "city")
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    post world_context_action_path, params: {context: "inventory"}

    expect(response).to redirect_to(inventory_path)
    expect(ArenaMatch.count).to eq(0)
  end

  it "requires authentication" do
    sign_out user

    post world_context_action_path, params: {context: "inventory"}

    expect(response).to redirect_to(new_user_session_path)
    expect(ArenaMatch.count).to eq(0)
  end
end
