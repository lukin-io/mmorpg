# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat Turn Interface", type: :system do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, current_hp: 100, max_hp: 100) }
  let(:zone) { create(:zone) }
  let(:npc) { create(:npc_template, level: 1, metadata: {"stats" => {"hp" => 50, "attack" => 10, "defense" => 5}}) }
  let(:battle) do
    create(:battle,
      initiator: character,
      zone: zone,
      status: :active,
      combat_mode: "simultaneous",
      action_points_per_turn: 80)
  end
  let!(:player_participant) do
    create(:battle_participant,
      battle: battle,
      character: character,
      team: "alpha",
      is_alive: true,
      current_hp: 100,
      max_hp: 100,
      current_mp: 50,
      max_mp: 50,
      participant_type: "player")
  end
  let!(:npc_participant) do
    create(:battle_participant,
      battle: battle,
      npc_template: npc,
      team: "beta",
      is_alive: true,
      current_hp: 50,
      max_hp: 50,
      participant_type: "npc")
  end

  before do
    login_as(user, scope: :user)
    create(:character_position, character: character, zone: zone)
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character)
  end

  describe "combat interface display" do
    it "shows both participants with HP bars" do
      visit battle_path(battle)

      expect(page).to have_css(".nl-participant--player")
      expect(page).to have_css(".nl-participant--opponent")
      expect(page).to have_css(".nl-hp-fill")
    end

    it "shows action point display" do
      visit battle_path(battle)

      expect(page).to have_css(".nl-ap-panel")
      expect(page).to have_content("Action Points")
      expect(page).to have_content("Limit: 80")
    end

    it "shows attack dropdowns for all body parts" do
      visit battle_path(battle)

      expect(page).to have_css('[data-body-part="head"]')
      expect(page).to have_css('[data-body-part="torso"]')
      expect(page).to have_css('[data-body-part="stomach"]')
      expect(page).to have_css('[data-body-part="legs"]')
    end

    it "shows block options" do
      visit battle_path(battle)

      expect(page).to have_css(".nl-block-select")
    end

    it "shows combat log" do
      visit battle_path(battle)

      expect(page).to have_css(".nl-combat-log")
    end

    it "shows combat rules reference" do
      visit battle_path(battle)

      expect(page).to have_content("Combat Rules")
      expect(page).to have_content("Multi-Attack Penalty")
    end
  end

  describe "action selection", js: true do
    it "updates AP display when selecting attack" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"

      # Simple attacks cost 0 AP
      expect(page).to have_content("Used:")
    end

    it "shows multi-attack penalty when selecting multiple attacks", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"
      select "Simple Attack (0 AP)", from: "attacks[torso]"

      # Should show penalty notice (25 AP penalty for 2 attacks)
      expect(page).to have_css(".nl-penalty-notice:not([style*='display: none'])")
    end

    it "disables legs when head is selected (exclusivity rule)", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"

      # Legs dropdown should be disabled
      expect(page).to have_css('[data-body-part="legs"][disabled]')
    end

    it "disables other blocks when one is selected", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Block (30 AP)", from: "blocks[head]"

      # Other block dropdowns should be disabled
      expect(page).to have_css('[data-body-part="torso"].nl-block-select[disabled]')
    end

    it "enables submit button when valid actions selected", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      expect(page).to have_button("Execute Turn", disabled: true)

      select "Simple Attack (0 AP)", from: "attacks[head]"

      expect(page).to have_button("Execute Turn", disabled: false)
    end

    it "shows warning when AP limit exceeded", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      # Select multiple high-cost targeted attacks to exceed 80 AP
      # Head Strike (35) + Torso Strike (30) + Stomach Strike (30) + penalty = over 80
      select "Head Strike (35 AP)", from: "attacks[head]"
      select "Torso Strike (30 AP)", from: "attacks[torso]"
      select "Stomach Strike (30 AP)", from: "attacks[stomach]"

      expect(page).to have_css(".nl-ap-warning:not([style*='display: none'])")
    end
  end

  describe "turn submission", js: true do
    it "submits turn and shows waiting state", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"
      click_button "Execute Turn"

      # Should show waiting state
      expect(page).to have_content("Waiting")
    end

    it "shows confirmation flash message", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"
      click_button "Execute Turn"

      expect(page).to have_css(".nl-flash--success")
    end
  end

  describe "reset functionality", js: true do
    it "resets all selections when clicking reset", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"
      select "Block (30 AP)", from: "blocks[torso]"

      click_button "Reset"

      # Verify reset
      expect(page.find('[data-body-part="head"].nl-attack-select').value).to eq("")
      expect(page.find('[data-body-part="torso"].nl-block-select').value).to eq("")
    end

    it "re-enables all disabled dropdowns on reset", skip: "Stimulus controller behavior not yet implemented" do
      visit battle_path(battle)

      select "Simple Attack (0 AP)", from: "attacks[head]"
      # Legs should be disabled

      click_button "Reset"

      # Legs should be enabled again
      expect(page).not_to have_css('[data-body-part="legs"][disabled]')
    end
  end

  describe "battle completion" do
    it "shows victory screen when player wins" do
      battle.update!(status: :completed, winning_team: "alpha")

      visit battle_path(battle)

      expect(page).to have_content("Victory")
    end

    it "shows defeat screen when player loses" do
      battle.update!(status: :completed, winning_team: "beta")
      player_participant.update!(is_alive: false, current_hp: 0)

      visit battle_path(battle)

      expect(page).to have_content("Defeat").or have_content("Defeated")
    end

    it "shows return to world link after battle" do
      battle.update!(status: :completed, winning_team: "alpha")

      visit battle_path(battle)

      expect(page).to have_link("Return to World")
    end
  end

  describe "authorization" do
    it "redirects non-participants", skip: "Authorization redirect not yet implemented in BattlesController" do
      other_user = create(:user)
      other_character = create(:character, user: other_user)
      create(:character_position, character: other_character, zone: zone)

      Warden.test_reset!
      login_as(other_user, scope: :user)

      visit battle_path(battle)

      expect(page).to have_current_path(root_path).or have_current_path(world_path)
    end
  end
end
