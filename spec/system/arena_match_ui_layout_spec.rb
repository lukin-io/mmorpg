# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena Match UI Layout", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  let(:user1) { create(:user, email: "player1@test.com", password: "password123") }
  let(:user2) { create(:user, email: "player2@test.com", password: "password123") }
  let(:character1) { create(:character, user: user1, name: "WarriorAlpha", level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, name: "MageBeta", level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true, max_concurrent_matches: 5) }
  let(:arena_season) { create(:arena_season, status: :live) }

  let!(:match) do
    create(:arena_match,
      arena_room: arena_room,
      arena_season: arena_season,
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
    it "displays arena-pvp-layout container" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-pvp-layout")
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

    it "shows fighter name and level" do
      visit arena_match_path(match)
      expect(page).to have_content("WarriorAlpha")
      expect(page).to have_css(".fighter-level", text: "[Lv.10]")
    end

    it "shows HP bar with percentage" do
      visit arena_match_path(match)
      expect(page).to have_content("100/100")
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
      expect(page).to have_button("Submit Turn")
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

    it "shows shield block table when current fighter has a shield equipped" do
      shield = create(:item_template,
        name: "Arena Shield",
        slot: "off_hand",
        stat_modifiers: {"defense" => 8, "weapon_family" => "shield"})
      create(:inventory_item, inventory: character1.inventory, item_template: shield, equipped: true)

      visit arena_match_path(match)
      expect(page).to have_css(".nl-fight-selector-table option", text: "Shield Torso Block [ 40 ]")
    end
  end

  describe "Combat Log" do
    it "displays combat log container" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-combat-log")
    end

    it "shows FIGHT message for live match" do
      visit arena_match_path(match)
      expect(page).to have_css(".combat-log-entry", text: "FIGHT!")
    end
  end

  describe "Match Info Panel" do
    it "displays match info bar" do
      visit arena_match_path(match)
      expect(page).to have_css(".arena-match-bar")
    end

    it "shows match type" do
      visit arena_match_path(match)
      expect(page).to have_content("Duel")
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
      # Stats use emoji shorthand: 💪 for strength, 🏃 for dex, 🍀 for luck
      expect(page).to have_content("💪")
    end

    it "displays strength emoji" do
      visit arena_match_path(match)
      expect(page).to have_content("💪")
    end

    it "displays dexterity emoji" do
      visit arena_match_path(match)
      expect(page).to have_content("🏃")
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
      expect(page).to have_css(".badge--completed", text: "Completed")
    end
  end

  describe "Victory/Defeat Overlay" do
    context "when current user wins" do
      before do
        character2.update!(current_hp: 0)
      end

      it "shows VICTORY text" do
        visit arena_match_path(match)
        expect(page).to have_css(".arena-result--victory")
        expect(page).to have_content("VICTORY")
      end

      it "shows winner name" do
        visit arena_match_path(match)
        expect(page).to have_content("WarriorAlpha")
      end

      it "shows finish fight button before returning to arena" do
        visit arena_match_path(match)
        expect(page).to have_button("Finish Fight")
      end

      it "shows Return to Arena after the result screen is finished" do
        participation1.update!(metadata: {"finished_at" => Time.current.iso8601})

        visit arena_match_path(match)
        expect(page).to have_link("Return to Arena")
      end
    end

    context "when current user loses" do
      before do
        character1.update!(current_hp: 0)
      end

      it "shows DEFEAT text" do
        visit arena_match_path(match)
        expect(page).to have_css(".arena-result--defeat")
        expect(page).to have_content("DEFEAT")
      end
    end
  end

  describe "Spectator View" do
    let(:spectator_user) { create(:user, email: "spectator@test.com", password: "password123") }
    let(:spectator_character) { create(:character, user: spectator_user, name: "Spectator", level: 5) }

    before do
      create(:character_position, character: spectator_character)
      login_as(spectator_user, scope: :user)
      allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(spectator_character)
    end

    it "hides action panel for spectators" do
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
        expect(page).to have_css(".arena-pvp-layout")
        expect(page).to have_content("WarriorAlpha")
        expect(page).to have_content("MageBeta")
      end
    end
  end
end
