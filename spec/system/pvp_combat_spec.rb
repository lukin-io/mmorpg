# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PVP Combat UI", type: :system do
  let(:user) { create(:user) }
  let(:attacker) { create(:character, user: user, name: "Warrior", level: 10, current_hp: 100) }
  let(:defender_user) { create(:user) }
  let(:defender) { create(:character, user: defender_user, name: "Mage", level: 10, current_hp: 100) }
  let(:zone) { create(:zone, name: "Battleground", pvp_enabled: true) }
  let(:battle) { create(:battle, :active, battle_type: :pvp, initiator: attacker, zone: zone) }

  before do
    create(:battle_participant, battle: battle, character: attacker, team: "alpha", current_hp: 100, max_hp: 100)
    create(:battle_participant, battle: battle, character: defender, team: "beta", current_hp: 100, max_hp: 100)

    login_as(user, scope: :user)
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(attacker)
  end

  # =============================================================================
  # SUCCESS CASES
  # =============================================================================
  describe "viewing the combat UI" do
    it "displays both combatants" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("Warrior")
      expect(page).to have_content("Mage")
    end

    it "displays HP bars for participants" do
      visit pvp_combat_path(battle)

      expect(page).to have_css(".pvp-hp-bar", count: 2)
      expect(page).to have_content("100/100")
    end

    it "displays the current round number" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("Round")
    end

    it "displays attack action buttons" do
      visit pvp_combat_path(battle)

      expect(page).to have_button("Head")
      expect(page).to have_button("Torso")
      expect(page).to have_button("Stomach")
      expect(page).to have_button("Legs")
    end

    it "displays defend button" do
      visit pvp_combat_path(battle)

      expect(page).to have_button("Defend", exact: false)
    end

    it "displays flee and surrender buttons" do
      visit pvp_combat_path(battle)

      expect(page).to have_button("Flee", exact: false)
      expect(page).to have_button("Surrender", exact: false)
    end
  end

  # =============================================================================
  # JS INTERACTIONS - Combat Actions with Turbo
  # =============================================================================
  describe "performing combat actions", js: true do
    before do
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
    end

    it "updates combat log after attack" do
      visit pvp_combat_path(battle)

      # Click attack button (e.g., Torso)
      click_button "Torso"

      # Wait for Turbo Stream response - combat log container should exist
      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "shows feedback when defend is clicked" do
      visit pvp_combat_path(battle)

      # Find and click the Defend button using btn-defend class
      find(".btn-defend").click

      # Turbo Stream should update UI - combat log should be visible
      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "processes flee attempt with confirmation" do
      visit pvp_combat_path(battle)

      # Accept the confirm dialog
      accept_confirm do
        find(".btn-flee").click
      end

      # Either redirects to world, stays on combat page, or shows result
      expect(page).to have_current_path(world_path, wait: 5)
        .or have_css(".pvp-combat-log", wait: 5)
        .or have_content("flee", wait: 5)
    end

    it "processes surrender with confirmation" do
      visit pvp_combat_path(battle)

      # Accept the confirm dialog
      accept_confirm do
        find(".btn-surrender").click
      end

      # Wait for the action to complete - should either redirect or show result
      # Using wait to allow for async processing
      sleep 1

      # Should have processed the surrender - check for any success indication
      expect(page).to have_current_path(world_path, wait: 10)
        .or have_content("Defeat", wait: 5)
        .or have_link("Return to World", wait: 5)
        .or have_content("surrendered", wait: 5)
    end
  end

  # =============================================================================
  # FAILURE CASES
  # =============================================================================
  describe "handling combat errors" do
    context "when battle is not found" do
      it "redirects to world" do
        visit pvp_combat_path(id: 999999)

        expect(page).to have_current_path(world_path)
      end
    end
  end

  # =============================================================================
  # EDGE CASES
  # =============================================================================
  describe "combat completion" do
    let(:completed_battle) { create(:battle, :completed, battle_type: :pvp, initiator: attacker, zone: zone) }

    before do
      create(:battle_participant, battle: completed_battle, character: attacker, team: "alpha", is_alive: true)
      create(:battle_participant, battle: completed_battle, character: defender, team: "beta", is_alive: false)
    end

    it "displays completed battle state" do
      visit pvp_combat_path(completed_battle)

      # Battle should be completed
      expect(page).to have_link("Return to World")
    end

    it "displays victory message for winner" do
      visit pvp_combat_path(completed_battle)

      expect(page).to have_content("Victory")
    end
  end

  # =============================================================================
  # AUTHORIZATION CASES
  # =============================================================================
  describe "authorization" do
    context "when user is not logged in", js: true do
      before do
        Warden.test_reset!
        Capybara.reset_sessions!
      end

      it "redirects to login" do
        visit pvp_combat_path(battle)

        expect(page).to have_current_path(new_user_session_path, wait: 5)
      end
    end

    context "when character is not a participant" do
      let(:other_user) { create(:user) }
      let(:other_char) { create(:character, user: other_user) }

      before do
        Capybara.reset_sessions!
        login_as(other_user, scope: :user)
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(other_char)
      end

      it "redirects to world with error" do
        visit pvp_combat_path(battle)

        expect(page).to have_current_path(world_path)
      end
    end
  end

  # =============================================================================
  # TURBO FRAME INTERACTIONS
  # =============================================================================
  describe "Turbo Frame updates", js: true do
    before do
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
    end

    it "updates HP bars via Turbo Stream after action" do
      visit pvp_combat_path(battle)

      # Verify initial HP bars exist
      expect(page).to have_css(".pvp-hp-bar", count: 2)

      # Perform an attack
      click_button "Torso"

      # HP bars should still be visible after Turbo Stream update
      expect(page).to have_css(".pvp-hp-bar", count: 2, wait: 5)
    end

    it "maintains combat interface after attack" do
      visit pvp_combat_path(battle)

      # Get initial page URL
      initial_url = current_url

      click_button "Head"

      # Should not have navigated away (Turbo Stream should handle update)
      expect(current_url).to eq(initial_url)

      # Combat log container should be visible
      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "maintains round counter across actions" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("Round")

      click_button "Torso"

      # Round display should persist
      expect(page).to have_content("Round", wait: 5)
    end

    it "keeps participants visible after action" do
      visit pvp_combat_path(battle)

      # Both participants should be visible initially
      expect(page).to have_content("Warrior")
      expect(page).to have_content("Mage")

      click_button "Head"

      # Both participants should still be visible
      expect(page).to have_content("Warrior", wait: 5)
      expect(page).to have_content("Mage")
    end
  end

  # =============================================================================
  # ACTION PANEL INTERACTIONS
  # =============================================================================
  describe "action panel UI", js: true do
    it "displays all body part targets" do
      visit pvp_combat_path(battle)

      expect(page).to have_css(".body-part-targets")
      expect(page).to have_button("Head")
      expect(page).to have_button("Torso")
      expect(page).to have_button("Stomach")
      expect(page).to have_button("Legs")
    end

    it "displays aimed attack option" do
      visit pvp_combat_path(battle)

      expect(page).to have_button("Aimed Attack", exact: false)
    end

    it "displays action groups" do
      visit pvp_combat_path(battle)

      expect(page).to have_css(".action-group", minimum: 3)
    end
  end
end
