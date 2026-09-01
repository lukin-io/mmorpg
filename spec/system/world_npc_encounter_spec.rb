# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wilderness NPC encounter delivery", type: :system, js: true do
  let(:user) { create(:user, email: "wilderness-browser@test.com", password: "password123") }
  let(:character) { create(:character, user:, name: "WildernessBrowser", current_hp: 200, max_hp: 200) }
  let(:zone) { create(:zone, name: "Browser Encounter Woods", location_type: "outdoor") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:tile_npc) do
    create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)
  end

  before do
    login_as(user, scope: :user)
    stub_const("Game::World::PassiveEncounterCheck::MIN_DELAY_SECONDS", 0)
    stub_const("Game::World::PassiveEncounterCheck::MAX_DELAY_SECONDS", 0)
  end

  it "replaces the wilderness surface with the shared 1xN fight when the shell check resolves" do
    visit world_path

    expect(page).to have_css(
      "body[data-game-layout-encounter-url-value='#{world_encounter_check_path}']"
    )

    expect(page).to have_current_path(%r{/arena_matches/\d+}, wait: 5)
    match = ArenaMatch.order(:id).last
    expect(page).to have_current_path(arena_match_path(match))
    expect(page).to have_css(".arena-match-page")
    expect(page).to have_css(".fighter-card--npc", count: 2)
    expect(page).to have_css(".nl-fight-target-line", text: tile_npc.display_name)
    expect(match.metadata).to include("source" => "world_npc", "encounter_count" => 2)
  end
end
