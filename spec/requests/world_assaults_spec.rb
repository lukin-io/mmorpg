# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World location assaults", type: :request do
  let(:zone) { create(:zone, name: "Assault Road", location_type: "outdoor") }
  let(:attacker) { create(:character, name: "ReqAttacker", level: 4, current_hp: 100, max_hp: 100) }
  let(:defender) { create(:character, name: "ReqDefender", level: 4, current_hp: 100, max_hp: 100) }

  before do
    create(:character_position, character: attacker, zone:, x: 2, y: 2)
    create(:character_position, character: defender, zone:, x: 2, y: 2)
    create(:user_session, user: attacker.user)
    create(:user_session, user: defender.user)
    Game::Professions::Templates.ensure_craft_items!
    template = ItemTemplate.find_by!(key: "combat_trauma_scroll")
    Game::Inventory::Manager.new(inventory: attacker.inventory).add_item!(item_template: template, quantity: 1)
    sign_in attacker.user, scope: :user
  end

  it "starts a same-cell world PvP match through the assault route" do
    expect {
      post world_assault_path, params: {defender_id: defender.id, assault_scroll_kind: "bloody"}
    }.to change(ArenaMatch, :count).by(1)

    match = ArenaMatch.last
    expect(response).to redirect_to(arena_match_path(match))
    expect(match.metadata["source"]).to eq("world_pvp")
    expect(match.metadata["assault_scroll_kind"]).to eq("bloody")
    expect(match.metadata["combat_trauma"]).to eq(true)
  end

  it "does not create a match when the scroll is missing" do
    template = ItemTemplate.find_by!(key: "combat_trauma_scroll")
    Game::Inventory::Manager.new(inventory: attacker.inventory).remove_item!(item_template: template, quantity: 1)

    expect {
      post world_assault_path, params: {defender_id: defender.id}
    }.not_to change(ArenaMatch, :count)

    expect(response).to redirect_to(world_path(assault_denied: 1))
  end
end
