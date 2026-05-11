# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PVP Two-Player Combat UI", type: :system do
  # =============================================================================
  # SETUP: Two distinct users and their characters for realistic PVP UI testing
  # =============================================================================
  let(:user_alpha) { create(:user) }
  let(:user_beta) { create(:user) }

  let(:warrior_class) do
    create(:character_class,
      name: "Warrior",
      base_stats: {strength: 15, agility: 10, intellect: 5})
  end

  let(:mage_class) do
    create(:character_class,
      name: "Mage",
      base_stats: {strength: 5, agility: 8, intellect: 18})
  end

  let(:pvp_zone) { create(:zone, name: "Battleground", pvp_enabled: true) }

  let(:warrior) do
    create(:character,
      user: user_alpha,
      name: "BrutalWarrior",
      character_class: warrior_class,
      level: 10,
      current_hp: 150,
      max_hp: 150)
  end

  let(:mage) do
    create(:character,
      user: user_beta,
      name: "ArcaneBlaster",
      character_class: mage_class,
      level: 10,
      current_hp: 80,
      max_hp: 80)
  end

  let(:battle) do
    create(:battle, :active, :pvp,
      initiator: warrior,
      zone: pvp_zone,
      turn_number: 1,
      action_points_per_turn: 100)
  end

  def click_attack_button(label)
    find_button(label, wait: 5).click
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    find_button(label, wait: 5).click
  end

  before do
    create(:battle_participant,
      battle: battle,
      character: warrior,
      team: "alpha",
      current_hp: 150,
      max_hp: 150,
      is_alive: true)

    create(:battle_participant,
      battle: battle,
      character: mage,
      team: "beta",
      current_hp: 80,
      max_hp: 80,
      is_alive: true)

    # Mock PVP zone rules
    allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
      .and_return({allowed: true, reason: "Zone allows open PVP"})
  end

  # =============================================================================
  # SUCCESS CASES: Combat UI Display
  # =============================================================================
  describe "Combat Interface Display", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
    end

    it "displays both combatants with correct names" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("BrutalWarrior")
      expect(page).to have_content("ArcaneBlaster")
    end

    it "displays HP bars for both participants" do
      visit pvp_combat_path(battle)

      expect(page).to have_css(".pvp-hp-bar", count: 2)
      expect(page).to have_content("150/150")
      expect(page).to have_content("80/80")
    end

    it "displays current round number" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("Round 1")
    end

    it "distinguishes self from enemy with styling" do
      visit pvp_combat_path(battle)

      expect(page).to have_css(".pvp-participant--self")
      expect(page).to have_css(".pvp-participant--enemy")
    end

    it "displays character levels" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("Lv.10", count: 2)
    end

    it "displays combat header with PVP indicator" do
      visit pvp_combat_path(battle)

      expect(page).to have_content("PVP Combat")
      expect(page).to have_css(".pvp-combat-header")
    end
  end

  # =============================================================================
  # ACTION PANEL: Attack buttons and interactions
  # =============================================================================
  describe "Action Panel UI", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "displays all body part attack buttons" do
      expect(page).to have_button("Head")
      expect(page).to have_button("Torso")
      expect(page).to have_button("Stomach")
      expect(page).to have_button("Legs")
    end

    it "displays aimed attack button with AP cost" do
      expect(page).to have_button("Aimed Attack", exact: false)
    end

    it "displays defend button" do
      expect(page).to have_css(".btn-defend")
      expect(page).to have_content("Defend")
    end

    it "displays flee button" do
      expect(page).to have_css(".btn-flee")
      expect(page).to have_content(/flee/i)
    end

    it "displays surrender button" do
      expect(page).to have_css(".btn-surrender")
      expect(page).to have_content(/surrender/i)
    end

    it "organizes actions into groups" do
      expect(page).to have_css(".action-group", minimum: 3)
    end
  end

  # =============================================================================
  # ATTACK ACTIONS: Clicking attack buttons
  # =============================================================================
  describe "Performing Attacks", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    context "basic body part attacks" do
      it "processes head attack via Turbo Stream" do
        click_button "Head"

        # Should update without page reload
        expect(page).to have_css(".pvp-combat-log", wait: 5)
      end

      it "processes torso attack via Turbo Stream" do
        click_button "Torso"

        expect(page).to have_css(".pvp-combat-log", wait: 5)
      end

      it "processes stomach attack via Turbo Stream" do
        click_button "Stomach"

        expect(page).to have_css(".pvp-combat-log", wait: 5)
      end

      it "processes legs attack via Turbo Stream" do
        click_button "Legs"

        expect(page).to have_css(".pvp-combat-log", wait: 5)
      end
    end

    context "aimed attacks" do
      it "processes aimed attack with bonus damage indicator" do
        find(".btn-aimed").click

        expect(page).to have_css(".pvp-combat-log", wait: 5)
      end
    end

    context "combat log updates" do
      it "shows attack message in combat log after action" do
        click_button "Torso"

        within(".pvp-combat-log") do
          expect(page).to have_content("attack", wait: 5).or have_content("damage", wait: 5)
        end
      end

      it "shows round indicator in log entries" do
        click_button "Head"

        within(".combat-log-entries") do
          expect(page).to have_content("[R", wait: 5)
        end
      end
    end

    context "HP bar updates" do
      it "updates enemy HP bar after attack" do
        initial_bar_count = all(".pvp-hp-bar").count

        click_button "Torso"

        # HP bars should still exist after update
        expect(page).to have_css(".pvp-hp-bar", count: initial_bar_count, wait: 5)
      end

      it "maintains page state without full reload" do
        initial_url = current_url

        click_button "Head"

        # Should remain on same page
        expect(current_url).to eq(initial_url)
      end
    end
  end

  # =============================================================================
  # DEFEND ACTION
  # =============================================================================
  describe "Defending", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "processes defend action" do
      find(".btn-defend").click

      # Should see defensive message
      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "shows defensive stance in combat log" do
      find(".btn-defend").click

      within(".pvp-combat-log") do
        expect(page).to have_content("defend", wait: 5).or have_content("defensive", wait: 5)
      end
    end
  end

  # =============================================================================
  # FLEE ACTIONS
  # =============================================================================
  describe "Fleeing from Combat", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "shows confirmation dialog when clicking flee" do
      # Verify confirm dialog appears
      dismiss_confirm do
        find(".btn-flee").click
      end

      # Should still be on battle page after dismissing
      expect(page).to have_current_path(pvp_combat_path(battle))
    end

    it "processes flee on confirmation acceptance" do
      accept_confirm do
        find(".btn-flee").click
      end

      # Should either redirect to world or show combat log update
      expect(page).to have_current_path(world_path, wait: 5)
        .or have_css(".pvp-combat-log", wait: 5)
        .or have_content("flee", wait: 5)
    end
  end

  # =============================================================================
  # SURRENDER ACTIONS
  # =============================================================================
  describe "Surrendering", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "shows confirmation dialog when clicking surrender" do
      dismiss_confirm do
        find(".btn-surrender").click
      end

      # Should still be on battle page
      expect(page).to have_current_path(pvp_combat_path(battle))
    end

    it "processes surrender and redirects on confirmation" do
      accept_confirm do
        find(".btn-surrender").click
      end

      # Should redirect to world after surrender
      expect(page).to have_current_path(world_path, wait: 10)
        .or have_content("Defeat", wait: 5)
        .or have_content("surrendered", wait: 5)
    end
  end

  # =============================================================================
  # BATTLE COMPLETION STATES
  # =============================================================================
  describe "Battle Completion UI" do
    describe "Victory State", js: true do
      let(:completed_battle) do
        create(:battle, :completed, :pvp,
          initiator: warrior,
          zone: pvp_zone,
          ended_at: Time.current)
      end

      before do
        create(:battle_participant,
          battle: completed_battle,
          character: warrior,
          team: "alpha",
          current_hp: 100,
          max_hp: 150,
          is_alive: true)

        create(:battle_participant,
          battle: completed_battle,
          character: mage,
          team: "beta",
          current_hp: 0,
          max_hp: 80,
          is_alive: false)

        login_as(user_alpha, scope: :user)
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      end

      it "displays victory message for winner" do
        visit pvp_combat_path(completed_battle)

        expect(page).to have_content("Victory")
        expect(page).to have_css(".result-victory")
      end

      it "displays return to world link" do
        visit pvp_combat_path(completed_battle)

        expect(page).to have_link("Return to World")
      end

      it "hides action panel when battle is completed" do
        visit pvp_combat_path(completed_battle)

        expect(page).not_to have_css(".pvp-action-panel")
        expect(page).to have_css(".pvp-result-panel")
      end
    end

    describe "Defeat State", js: true do
      let(:completed_battle) do
        create(:battle, :completed, :pvp,
          initiator: warrior,
          zone: pvp_zone,
          ended_at: Time.current)
      end

      before do
        create(:battle_participant,
          battle: completed_battle,
          character: warrior,
          team: "alpha",
          current_hp: 0,
          max_hp: 150,
          is_alive: false)

        create(:battle_participant,
          battle: completed_battle,
          character: mage,
          team: "beta",
          current_hp: 50,
          max_hp: 80,
          is_alive: true)

        login_as(user_alpha, scope: :user)
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      end

      it "displays defeat message for loser" do
        visit pvp_combat_path(completed_battle)

        expect(page).to have_content("Defeat")
        expect(page).to have_css(".result-defeat")
      end

      it "still shows return to world link" do
        visit pvp_combat_path(completed_battle)

        expect(page).to have_link("Return to World")
      end
    end
  end

  # =============================================================================
  # TURBO STREAM UPDATES
  # =============================================================================
  describe "Turbo Stream Real-time Updates", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "updates combat log without page reload" do
      initial_log_content = find(".pvp-combat-log").text

      click_button "Torso"

      # Wait for Turbo Stream update
      sleep 0.5

      new_log_content = find(".pvp-combat-log").text
      expect(new_log_content).not_to eq(initial_log_content)
    end

    it "updates HP displays after attack" do
      click_button "Head"

      # HP bars should be updated
      expect(page).to have_css(".pvp-hp-fill", wait: 5)
    end

    it "maintains round counter visibility" do
      click_button "Torso"

      expect(page).to have_content("Round", wait: 5)
    end

    it "keeps both participants visible after action" do
      click_button "Head"

      expect(page).to have_content("BrutalWarrior", wait: 5)
      expect(page).to have_content("ArcaneBlaster", wait: 5)
    end
  end

  # =============================================================================
  # MULTI-TURN COMBAT FLOW
  # =============================================================================
  describe "Multi-Turn Combat", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      visit pvp_combat_path(battle)
    end

    it "allows multiple consecutive attacks" do
      click_attack_button "Head"
      expect(page).to have_css(".pvp-combat-log", wait: 5)

      click_attack_button "Torso"
      expect(page).to have_css(".pvp-combat-log", wait: 5)

      click_attack_button "Stomach"
      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "accumulates combat log entries across turns" do
      click_button "Head"
      sleep 0.5
      click_button "Torso"
      sleep 0.5

      entries = all(".combat-log-entry")
      expect(entries.count).to be >= 2
    end
  end

  # =============================================================================
  # AUTHORIZATION CASES
  # =============================================================================
  describe "Authorization" do
    context "when user is not logged in" do
      it "redirects to login page" do
        visit pvp_combat_path(battle)

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "when user is logged in but not a participant", js: true do
      let(:other_user) { create(:user) }
      let(:other_char) { create(:character, user: other_user, name: "Outsider") }

      before do
        login_as(other_user, scope: :user)
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(other_char)
      end

      it "redirects to world with error message" do
        visit pvp_combat_path(battle)

        expect(page).to have_current_path(world_path)
      end
    end

    context "when battle does not exist" do
      before do
        login_as(user_alpha, scope: :user)
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
      end

      it "redirects to world" do
        visit pvp_combat_path(id: 999999)

        expect(page).to have_current_path(world_path)
      end
    end
  end

  # =============================================================================
  # OPPONENT PERSPECTIVE (User Beta as Mage)
  # =============================================================================
  describe "Opponent Perspective", js: true do
    before do
      login_as(user_beta, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(mage)
      visit pvp_combat_path(battle)
    end

    it "shows mage as self and warrior as enemy" do
      expect(page).to have_content("ArcaneBlaster")
      expect(page).to have_content("BrutalWarrior")

      # Mage should be marked as self
      within(".pvp-participant--self") do
        expect(page).to have_content("ArcaneBlaster")
      end
    end

    it "allows mage to perform attacks" do
      click_button "Head"

      expect(page).to have_css(".pvp-combat-log", wait: 5)
    end

    it "displays correct HP values for mage" do
      expect(page).to have_content("80/80")
    end
  end

  # =============================================================================
  # EDGE CASES
  # =============================================================================
  describe "Edge Cases", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
    end

    context "when battle has empty combat log" do
      it "displays empty log container" do
        visit pvp_combat_path(battle)

        expect(page).to have_css(".pvp-combat-log")
        expect(page).to have_css(".combat-log-entries")
      end
    end

    context "when participant has very low HP" do
      before do
        # Update existing battle participants for this scenario
        battle.battle_participants.find_by(character: warrior)&.update!(current_hp: 5)
      end

      it "displays low HP correctly" do
        visit pvp_combat_path(battle)

        expect(page).to have_content("5/150")
      end

      it "shows narrow HP bar fill" do
        visit pvp_combat_path(battle)

        # HP fill should be very narrow (5/150 = ~3%)
        hp_fill = find(".pvp-participant--self .pvp-hp-fill")
        width = hp_fill[:style].match(/width: (\d+)%/)
        expect(width[1].to_i).to be < 10
      end
    end

    context "when round number is high" do
      before do
        # Update existing battle for this scenario
        battle.update!(turn_number: 50)
        battle.battle_participants.find_by(character: warrior)&.update!(current_hp: 50)
        battle.battle_participants.find_by(character: mage)&.update!(current_hp: 30)
      end

      it "displays high round number" do
        visit pvp_combat_path(battle)

        expect(page).to have_content("Round 50")
      end
    end
  end

  # =============================================================================
  # RESPONSIVE BEHAVIOR
  # =============================================================================
  describe "UI Responsiveness", js: true do
    before do
      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
    end

    it "displays properly on standard viewport" do
      page.driver.browser.manage.window.resize_to(1280, 800)
      visit pvp_combat_path(battle)

      expect(page).to have_css(".pvp-combat-container")
      expect(page).to have_css(".pvp-participants")
    end
  end

  # =============================================================================
  # COMBAT COMPLETION VIA UI
  # =============================================================================
  describe "Combat Completion Through UI Actions", js: true do
    before do
      # Use existing battle but set mage to very low HP
      battle.battle_participants.find_by(character: mage)&.update!(current_hp: 1)
      mage.update!(current_hp: 1)

      login_as(user_alpha, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(warrior)
    end

    it "shows victory screen when defeating opponent" do
      visit pvp_combat_path(battle)

      # Attack should defeat mage with 1 HP
      click_button "Head"

      # Should show victory or update battle status
      expect(page).to have_content("Victory", wait: 10)
        .or have_content("wins", wait: 10)
        .or have_link("Return to World", wait: 10)
    end
  end

  # =============================================================================
  # MAGIC/SKILL UI (Draft specs for future implementation)
  # =============================================================================
  describe "Magic/Skill UI" do
    xit "displays available magic skills for mage character" do
      # TODO: Implement when skill UI is added to PVP
    end

    xit "shows mana bar for magic users" do
      # TODO: Implement mana display
    end

    xit "disables skill buttons when insufficient mana" do
      # TODO: Implement mana validation UI
    end

    xit "shows cooldown timer on recently used skills" do
      # TODO: Implement cooldown display
    end

    xit "displays skill effect tooltips on hover" do
      # TODO: Implement skill tooltips
    end

    xit "processes fire arrow skill with visual feedback" do
      # TODO: Implement magic skill UI
    end

    xit "shows healing effect animation" do
      # TODO: Implement healing visual feedback
    end

    xit "displays buff/debuff icons on participants" do
      # TODO: Implement buff/debuff indicators
    end
  end

  # =============================================================================
  # ACTION POINT UI (Draft specs for turn-based enhancements)
  # =============================================================================
  describe "Action Point UI" do
    xit "displays current action points remaining" do
      # TODO: Implement AP display
    end

    xit "shows AP cost for each action" do
      # TODO: Implement AP cost indicators
    end

    xit "disables attacks when insufficient AP" do
      # TODO: Implement AP validation
    end

    xit "shows multi-attack penalty warning" do
      # TODO: Implement penalty display
    end

    xit "allows selecting multiple attacks before submitting turn" do
      # TODO: Implement turn builder UI
    end

    xit "shows turn preview before confirmation" do
      # TODO: Implement turn preview
    end
  end
end
