# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena Match UI Layout", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  let(:user1) { create(:user, email: "player1@test.com", password: "password123") }
  let(:user2) { create(:user, email: "player2@test.com", password: "password123") }
  let(:character1) { create(:character, user: user1, name: "WarriorAlpha", level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, name: "MageBeta", level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true, max_concurrent_matches: 5) }
  let!(:match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      turn_timeout_seconds: 300,
      started_at: Time.current)
  end

  let!(:participation1) { create(:arena_participation, arena_match: match, character: character1, user: user1, team: "a") }
  let!(:participation2) { create(:arena_participation, arena_match: match, character: character2, user: user2, team: "b") }

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
    login_as(user1, scope: :user)
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character1)
  end

  describe "3-Column Layout", js: true do
    it "displays arena-fight-layout container" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-fight-layout")
    end

    it "displays left player section" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-fighter--left")
    end

    it "displays center combat section" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-center")
    end

    it "displays right player section with info" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-fighter--right")
    end

    it "shows current user in left column" do
      visit arena_match_path(match)
      within(".arena-fighter--left") do
        expect(page).to have_content("WarriorAlpha")
      end
    end

    it "shows opponent in right column" do
      visit arena_match_path(match)
      within(".arena-fighter--right") do
        expect(page).to have_content("MageBeta")
      end
    end
  end

  describe "Fighter Cards" do
    it "displays fighter-card for each participant" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-fighter", count: 2)
    end

    it "renders the source equipment paper doll around both combatants" do
      visit arena_match_path(match)

      expect(page).to have_css(".fighter-paperdoll .nl-doll", count: 2)
      expect(page).to have_css(".fighter-paperdoll .nl-doll-slot", count: EquipmentSlots::KEYS.size * 2)
    end

    it "shows fighter name and level" do
      visit arena_match_path(match)
      expect(page).to have_content("WarriorAlpha")
      expect(page).to have_css(".fighter-level", text: "[10]")
    end

    it "shows HP bar with percentage" do
      visit arena_match_path(match)
      expect(page).to have_content("100/100")
    end

    it "renders complete ManyxMany side rosters" do
      teammate_a = create(:character, name: "TeamAlpha")
      teammate_b = create(:character, name: "TeamBeta")
      create(:arena_participation, arena_match: match, character: teammate_a, user: teammate_a.user, team: "a")
      create(:arena_participation, arena_match: match, character: teammate_b, user: teammate_b.user, team: "b")

      visit arena_match_path(match)

      expect(page).to have_css(".arena-fighter--left .fighter-card", count: 2)
      expect(page).to have_css(".arena-fighter--right .fighter-card", count: 2)
      expect(page).to have_content("TeamAlpha")
      expect(page).to have_content("TeamBeta")
    end

    it "gives repeated NPC templates unique participation target ids" do
      npc = create(:npc_template, name: "Twin Rat", npc_key: "twin_rat")
      first = create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b")
      second = create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b")

      visit arena_match_path(match)

      expect(page).to have_css(%([data-character-id="npc-participation-#{first.id}"]))
      expect(page).to have_css(%([data-character-id="npc-participation-#{second.id}"]))
    end

    it "applies correct HP color class for high HP", skip: "HP color classes not yet implemented" do
    end

    it "applies correct HP color class for critical HP", skip: "HP color classes not yet implemented" do
    end
  end

  describe "Combat Action Bar", js: true do
    it "displays action panel for participants" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-action-panel")
    end

    it "shows attack selectors with dynamic physical costs" do
      visit arena_match_path(match)
      expect(page).to have_css(".nl-fight-selector-table option", text: "Simple Attack [ 45 ]")
      expect(page).to have_css(".nl-fight-selector-table option", text: "Aimed Attack [ 65 ]")
    end

    it "shows turn submit button" do
      visit arena_match_path(match)
      expect(page).to have_button("Turn")
    end

    it "shows the five captured combat quick slots" do
      visit arena_match_path(match)

      expect(page).to have_css(".nl-fight-magic-slot", count: 5)
    end

    it "shows the current turn cost once beside the AP limit" do
      visit arena_match_path(match)

      expect(page).to have_css(".nl-fight-budget", text: /Used:\s*0\/\d+/)
      expect(page).not_to have_css(".nl-fight-budget", text: %r{0/\d+/\d+})
      expect(page).to have_button("Turn")
    end

    it "shows the fight-profile magic ceiling instead of current MP" do
      character1.update!(current_mp: 7, max_mp: 50)
      participation1.update!(
        metadata: {"combat_profile" => {"max_magic_mana" => 24}}
      )

      visit arena_match_path(match)

      expect(page).to have_css(".nl-fight-budget", text: /Mana:\s*5\.\.24/)
      expect(page).not_to have_css(".nl-fight-budget", text: /Mana:\s*5\.\.7/)
    end

    it "shows the Neverlands surrender action" do
      visit arena_match_path(match)

      expect(page).to have_button("Surrender")
    end

    it "shows body part selection dropdown" do
      visit arena_match_path(match)
      expect(page).to have_css(".nl-fight-selector-table select", minimum: 4)
    end

    it "shows defense/block selector" do
      visit arena_match_path(match)
      expect(page).to have_css(".nl-fight-selector-table option", text: "Torso Block [ 30 ]")
      expect(page).to have_css(".nl-fight-selector-table option", text: "Head Block [ 35 ]")
    end

    it "starts empty, locks the other block rows, and resets to zero used AP" do
      visit arena_match_path(match)
      torso_block = find(
        "select[data-arena-match-target='blockSelect'][data-body-part='torso']"
      )

      expect(all(".nl-fight-selector-table select").map(&:value)).to all(eq("none"))
      torso_block.find("option[value='torso_block']").select_option
      expect(page).to have_css("select[data-arena-match-target='blockSelect'][disabled]", count: 3)

      click_button "Reset"
      expect(all(".nl-fight-selector-table select").map(&:value)).to all(eq("none"))
      expect(page).to have_no_css("select[data-arena-match-target='blockSelect'][disabled]")
      expect(page).to have_css(".nl-fight-budget", text: /Used:\s*0\/\d+/)
    end

    it "shows the multi-attack penalty and warning while an over-budget Turn remains a no-op" do
      visit arena_match_path(match)
      torso_attack = find(
        "select[data-arena-match-target='attackSelect'][data-body-part='torso']"
      )
      stomach_attack = find(
        "select[data-arena-match-target='attackSelect'][data-body-part='stomach']"
      )

      torso_attack.find("option[value='aimed']").select_option
      stomach_attack.find("option[value='aimed']").select_option

      expect(page).to have_css(".nl-fight-penalty", text: "Penalty: 25")
      expect(page).to have_css(".nl-fight-over-budget", text: "OVER LIMIT!")
      expect(page).to have_button("Turn", disabled: false)

      click_button "Turn"

      expect(participation1.reload.metadata["pending_turn"]).to be_blank
      expect(match.combat_log_entries.where(log_type: "action")).to be_empty
    end

    it "shows only attacks and magic blocks injected by the fight profile" do
      match.update!(
        metadata: {
          "combat_profile" => {
            "injected_attack_keys" => %w[spirit_arrow mind_blast],
            "injected_block_keys" => %w[magic_shield rainbow_barrier crystal_sphere]
          }
        }
      )

      visit arena_match_path(match)

      expect(page).to have_css(".nl-fight-selector-table option", text: "Spirit Arrow [ 50 ]")
      expect(page).to have_css(".nl-fight-selector-table option", text: "Magic Shield [ 45/20 MP ]")
    end

    it "shows only the exact shield block table authored by the equipped shield" do
      shield = create(:item_template,
        name: "Arena Shield",
        slot: "off_hand",
        stat_modifiers: {"defense" => 8, "weapon_family" => "shield", "shield_block_table" => 90})
      create(:inventory_item, inventory: character1.inventory, item_template: shield, equipped: true)

      visit arena_match_path(match)
      expect(page).to have_css(
        ".nl-fight-selector-table option",
        text: "Shield: Head, Torso, and Abdomen [ 90 ]"
      )
      expect(page).not_to have_css(".nl-fight-selector-table option", text: "Shield: Head [ 40 ]")
    end
  end

  describe "Combat Log" do
    it "displays combat log container" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-combat-log")
    end

    it "shows fight-start message for live match" do
      visit arena_match_path(match)
      expect(page).to have_css(".combat-log-entry", text: "Fight started")
    end
  end

  describe "Match Info Panel" do
    it "displays match info bar" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-match-bar")
    end

    it "shows match type" do
      visit arena_match_path(match)
      expect(page).to have_content("Duels")
    end

    it "shows match status" do
      visit arena_match_path(match)
      expect(page).to have_css(".badge", text: "Live")
    end

    it "shows room name" do
      visit arena_match_path(match)
      expect(page).to have_content("Test Arena")
    end
  end

  describe "Opponent Stats Display" do
    it "shows opponent stats" do
      visit arena_match_path(match)
      expect(page).to have_content("Strength:")
    end

    it "displays strength label" do
      visit arena_match_path(match)
      expect(page).to have_content("Strength: 1")
    end

    it "displays dexterity label" do
      visit arena_match_path(match)
      expect(page).to have_content("Dexterity: 1")
    end
  end

  describe "Status Badge" do
    it "shows Live badge for active match" do
      visit arena_match_path(match)
      expect(page).to have_css(".badge--live", text: "Live")
    end

    it "shows Completed badge when match ends" do
      character2.update!(current_hp: 0)
      visit arena_match_path(match)
      expect(page).to have_css(".badge--completed", text: "Finished")
    end
  end

  describe "Victory/Defeat Overlay" do
    context "when current user wins" do
      before do
        character2.update!(current_hp: 0)
      end

      it "shows victory text" do
        visit arena_match_path(match)
        expect(page).to have_css(".arena-result--victory")
        expect(page).to have_content("Victory")
      end

      it "shows winner name" do
        visit arena_match_path(match)
        expect(page).to have_content("WarriorAlpha")
      end

      it "shows finish fight button before returning to arena" do
        visit arena_match_path(match)
        expect(page).to have_button("Finish Fight")
      end

      it "shows return to arena after the result screen is finished" do
        participation1.update!(metadata: {"finished_at" => Time.current.iso8601})

        visit arena_match_path(match)
        expect(page).to have_link("To Arena")
      end
    end

    context "when current user loses" do
      before do
        character1.update!(current_hp: 0)
      end

      it "shows defeat text" do
        visit arena_match_path(match)
        expect(page).to have_css(".arena-result--defeat")
        expect(page).to have_content("Defeat")
      end
    end

    context "when the match is a draw" do
      before do
        match.update!(status: :completed, ended_at: Time.current, winning_team: nil)
        participation1.update!(result: :draw, ended_at: Time.current)
        participation2.update!(result: :draw, ended_at: Time.current)
      end

      it "shows draw instead of defeat" do
        visit arena_match_path(match)

        expect(page).to have_css(".arena-result--draw .arena-result-title", text: "Draw")
        expect(page).not_to have_css(".arena-result-title", text: "Defeat")
      end
    end
  end

  describe "public fight-link view" do
    let(:viewer_user) { create(:user, email: "viewer@test.com", password: "password123") }
    let(:viewer_character) { create(:character, user: viewer_user, name: "Viewer", level: 5) }

    before do
      create(:character_position, character: viewer_character)
      login_as(viewer_user, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(viewer_character)
    end

    it "hides action panel for non-participants" do
      visit arena_match_path(match)
      expect(page).not_to have_css(".arena-action-panel")
    end

    it "shows Spectating text" do
      visit arena_match_path(match)
      expect(page).to have_content("Spectating")
    end

    context "when match ends" do
      before do
        character2.update!(current_hp: 0)
      end

      it "shows winner in combat log" do
        visit arena_match_path(match)
        expect(page).to have_content("Winner")
      end
    end
  end

  describe "Responsive Layout" do
    context "on mobile viewport", js: true do
      before do
        page.driver.browser.manage.window.resize_to(375, 667)
      end

      it "still displays all components" do
        visit arena_match_path(match)
        expect(page).to have_css(".arena-fight-layout")
        expect(page).to have_content("WarriorAlpha")
        expect(page).to have_content("MageBeta")
        expect(page.evaluate_script(<<~JS)).to be(true)
          (() => {
            const layout = document.querySelector(".arena-fight-layout")
            const main = document.querySelector(".nl-main-area")
            const page = document.querySelector(".arena-match-page")
            const styles = getComputedStyle(layout)
            return styles.gridTemplateAreas.includes("fighter-left") &&
              page.scrollWidth <= main.clientWidth + 1
          })()
        JS
      end
    end
  end
end
