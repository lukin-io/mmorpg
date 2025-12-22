# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# PvE Combat System Specs (Hotwire/Turbo Integration)
# =============================================================================
# Full browser integration tests for open world PvE combat with Hotwire.
# Tests cover: combat UI rendering, action buttons, HP bars, combat log.
#
# Related docs:
#   - doc/flow/16_combat_system.md
#   - doc/flow/4_world_npc_systems.md
# =============================================================================

RSpec.describe "PvE Combat UI", type: :system do
  include Warden::Test::Helpers

  # Setup pattern matching world_map_spec.rb - character belongs to user
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Whispering Woods", biome: "forest") }
  let(:character) { create(:character, user: user, name: "TestWarrior", level: 5, current_hp: 100, max_hp: 100) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

  let(:hostile_npc) do
    create(:npc_template,
      npc_key: "forest_goblin",
      name: "Forest Goblin",
      role: "hostile",
      level: 3,
      dialogue: "*snarls aggressively*",
      metadata: {
        "health" => 40,
        "base_damage" => 8,
        "xp_reward" => 25,
        "stats" => {"attack" => 10, "defense" => 5, "hp" => 40}
      })
  end

  before do
    driven_by(:rack_test)
  end

  # ===========================================================================
  # SUCCESS CASES: Combat Interface Rendering
  # ===========================================================================

  describe "active combat interface" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve,
        turn_number: 1)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 80,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 30,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "displays combat container" do
      visit combat_path

      expect(page).to have_css(".nl-combat-container").or have_css("[data-controller*='combat']").or have_content("Combat")
    end

    it "shows player participant name" do
      visit combat_path

      expect(page).to have_content("TestWarrior")
    end

    it "shows player level" do
      visit combat_path

      expect(page).to have_content("[5]")
    end

    it "shows NPC opponent name" do
      visit combat_path

      expect(page).to have_content("Forest Goblin")
    end

    it "shows NPC level" do
      visit combat_path

      expect(page).to have_content("[3]")
    end

    it "shows attack options" do
      visit combat_path

      expect(page).to have_content("Simple Attack").or have_content("Aimed Attack")
    end

    it "shows block options" do
      visit combat_path

      expect(page).to have_content("Basic Block").or have_content("Shield Block")
    end

    it "shows submit turn button" do
      visit combat_path

      expect(page).to have_button("Submit Turn").or have_button("Submit")
    end

    it "shows player HP in format 'current/max'" do
      visit combat_path

      expect(page).to have_content("80/100")
    end

    it "shows enemy HP in format 'current/max'" do
      visit combat_path

      expect(page).to have_content("30/40")
    end

    it "shows combat begins message in log" do
      visit combat_path

      expect(page).to have_content("Combat begins")
    end

    it "shows round number" do
      visit combat_path

      expect(page).to have_content("Round").or have_content("Turn")
    end

    it "shows action points" do
      visit combat_path

      expect(page).to have_content("Action Points")
    end

    it "shows body part selectors for attacks" do
      visit combat_path

      expect(page).to have_content("Head")
      expect(page).to have_content("Torso")
    end
  end

  # ===========================================================================
  # FAILURE CASES: No Active Combat
  # ===========================================================================

  describe "without active combat" do
    before { login_as(user, scope: :user) }

    it "redirects to world map" do
      visit combat_path

      expect(page).to have_current_path(world_path)
    end

    it "shows appropriate message" do
      visit combat_path

      expect(page).to have_content("not in combat").or have_current_path(world_path)
    end
  end

  # ===========================================================================
  # FAILURE CASES: Completed Battle
  # ===========================================================================

  describe "completed battle" do
    let!(:completed_battle) do
      create(:battle,
        status: :completed,
        initiator: character,
        battle_type: :pve)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: completed_battle,
        character: character,
        team: "player",
        is_alive: true)
    end

    before { login_as(user, scope: :user) }

    it "redirects away from completed battles" do
      visit combat_path

      # Should redirect since battle is complete
      expect(page).to have_current_path(world_path).or have_content("Victory").or have_content("not in combat")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Unauthenticated Access
  # ===========================================================================

  describe "unauthenticated user" do
    it "redirects to login when accessing combat" do
      visit combat_path

      expect(page).to have_current_path(/sign_in/).or have_content("sign in")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: Player at Low HP
  # ===========================================================================

  describe "player at critical HP" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 5,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 40,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "shows low HP value" do
      visit combat_path

      expect(page).to have_content("5/100")
    end

    it "still displays combat interface" do
      visit combat_path

      expect(page).to have_content("TestWarrior")
      expect(page).to have_content("Forest Goblin")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: NPC at Low HP
  # ===========================================================================

  describe "NPC at critical HP" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 100,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 1,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "shows NPC at 1 HP" do
      visit combat_path

      expect(page).to have_content("1/40")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: NPC with Empty Metadata
  # ===========================================================================

  describe "NPC with minimal metadata" do
    let(:minimal_npc) do
      create(:npc_template,
        npc_key: "minimal_enemy",
        name: "Mystery Creature",
        role: "hostile",
        level: 1,
        dialogue: "...",
        metadata: {})
    end

    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: minimal_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 30,
        max_hp: 30)
    end

    before { login_as(user, scope: :user) }

    it "displays NPC name correctly" do
      visit combat_path

      expect(page).to have_content("Mystery Creature")
    end

    it "shows NPC level" do
      visit combat_path

      expect(page).to have_content("[1]")
    end
  end

  # ===========================================================================
  # SUCCESS CASES: Victory Screen
  # ===========================================================================

  describe "victory after defeating NPC" do
    let!(:completed_battle) do
      create(:battle,
        status: :completed,
        initiator: character,
        battle_type: :pve,
        metadata: {"result" => "victory"})
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: completed_battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 50,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: completed_battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: false,
        current_hp: 0,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "shows victory or redirects appropriately" do
      visit combat_path

      # Either shows victory screen or redirects to world
      expect(page).to have_content("Victory").or have_current_path(world_path).or have_content("not in combat")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Defeat Screen
  # ===========================================================================

  describe "defeat when player dies" do
    let!(:completed_battle) do
      create(:battle,
        status: :completed,
        initiator: character,
        battle_type: :pve,
        metadata: {"result" => "defeat"})
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: completed_battle,
        character: character,
        team: "player",
        is_alive: false,
        current_hp: 0,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: completed_battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 20,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "shows defeat or redirects appropriately" do
      visit combat_path

      # Either shows defeat screen or redirects
      expect(page).to have_content("Defeat").or have_current_path(world_path).or have_content("not in combat")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: Multiple Enemies
  # ===========================================================================

  describe "battle with multiple NPC enemies" do
    let(:second_npc) do
      create(:npc_template,
        npc_key: "forest_wolf",
        name: "Forest Wolf",
        role: "hostile",
        level: 2,
        dialogue: "*growls*",
        metadata: {"health" => 25})
    end

    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true)
    end

    let!(:enemy1) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 40,
        max_hp: 40)
    end

    let!(:enemy2) do
      create(:battle_participant,
        battle: battle,
        npc_template: second_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 25,
        max_hp: 25)
    end

    before { login_as(user, scope: :user) }

    it "shows both enemy NPCs" do
      visit combat_path

      expect(page).to have_content("Forest Goblin")
      expect(page).to have_content("Forest Wolf")
    end
  end

  # ===========================================================================
  # SUCCESS CASES: Turn-based Combat Display
  # ===========================================================================

  describe "turn-based combat elements" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve,
        turn_number: 3)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 20,
        max_hp: 40)
    end

    before { login_as(user, scope: :user) }

    it "shows current turn/round number" do
      visit combat_path

      expect(page).to have_content("3").or have_content("Round")
    end

    it "shows reset button" do
      visit combat_path

      expect(page).to have_button("Reset")
    end
  end
end
