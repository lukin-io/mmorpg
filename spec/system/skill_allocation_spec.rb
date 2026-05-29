# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Skill Allocation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) do
    create(:character, user: user, combat_skill_points: 10, peace_skill_points: 5)
  end

  before do
    login_as(user, scope: :user)
    allow_any_instance_of(CharactersController).to receive(:current_character).and_return(character)
  end

  describe "skills page display" do
    before { visit skills_character_path(character) }

    it "displays the skill allocation page" do
      expect(page).to have_content("Skills")
      expect(page).to have_content(character.name)
    end

    it "displays both captured skill point pools" do
      within(".nl-allocation-pool--combat") do
        expect(page).to have_content("Combat points:")
        expect(page).to have_content("10")
      end

      within(".nl-allocation-pool--peace") do
        expect(page).to have_content("Peace points:")
        expect(page).to have_content("5")
      end
    end

    it "displays captured Neverlands skill categories" do
      expect(page).to have_content("Combat Skills")
      expect(page).to have_content("Magic")
      expect(page).to have_content("Resistances")
      expect(page).to have_content("Peace Skills")
      expect(page).not_to have_content("Survival")
    end

    it "displays skills with source-backed values and gains" do
      expect(page).to have_content("Unarmed Combat")
      expect(page).to have_content("Wanderer")
      expect(page).to have_content("[000/100]")
      expect(page).to have_css(".nl-skill-gain[data-skill='unarmed_combat']", text: "+10")
      expect(page).to have_css(".nl-skill-gain[data-skill='self_healing']", text: "+2")
    end

    it "does not display uncaptured formula previews" do
      expect(page).not_to have_content("Movement:")
      expect(page).not_to have_content("Damage:")
      expect(page).not_to have_css(".nl-skill-effect")
    end

    it "displays allocation controls" do
      expect(page).to have_button("Save", disabled: true)
      expect(page).to have_button("Reset")
    end
  end

  describe "adding skill points" do
    before { visit skills_character_path(character) }

    it "increments combat skill level when clicking +" do
      within_skill_row(:unarmed_combat) do
        click_button "+"
        expect(page).to have_content("[010/100]")
        expect(page).to have_content("(+10)")
      end

      within(".nl-allocation-pool--combat") { expect(page).to have_content("9") }
      expect(page).to have_button("Save", disabled: false)
    end

    it "increments peace skill level from the peace pool" do
      within_skill_row(:self_healing) do
        click_button "+"
        expect(page).to have_content("[002/100]")
        expect(page).to have_content("(+2)")
      end

      within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
      within(".nl-allocation-pool--peace") { expect(page).to have_content("4") }
    end

    it "applies captured tiered progression rates" do
      within_skill_row(:unarmed_combat) do
        3.times { click_button "+" }
        expect(page).to have_content("[030/100]")
        expect(page).to have_css(".nl-skill-gain", text: "+8")
      end
    end

    it "uses captured lower rates for other combat skills" do
      within_skill_row(:sword_mastery) do
        click_button "+"
        expect(page).to have_content("[008/100]")
        expect(page).to have_content("(+8)")
      end
    end

    it "can allocate to multiple skills simultaneously" do
      within_skill_row(:unarmed_combat) { click_button "+" }
      within_skill_row(:sword_mastery) { click_button "+" }
      within_skill_row(:two_handed_mastery) { click_button "+" }

      within_skill_row(:unarmed_combat) { expect(page).to have_content("[010/100]") }
      within_skill_row(:sword_mastery) { expect(page).to have_content("[008/100]") }
      within_skill_row(:two_handed_mastery) { expect(page).to have_content("[010/100]") }
      within(".nl-allocation-pool--combat") { expect(page).to have_content("7") }
    end
  end

  describe "removing skill points" do
    before do
      visit skills_character_path(character)
      within_skill_row(:unarmed_combat) { click_button "+" }
    end

    it "decrements skill level when clicking -" do
      within_skill_row(:unarmed_combat) do
        click_button "−"
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+10)")
      end
    end

    it "restores combat points and disables save when reset to original" do
      within_skill_row(:unarmed_combat) { click_button "−" }

      within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
      expect(page).to have_button("Save", disabled: true)
    end

    it "cannot remove below base level" do
      within_skill_row(:unarmed_combat) do
        click_button "−"
        click_button "−"
        expect(page).to have_content("[000/100]")
      end
    end
  end

  describe "reset functionality" do
    before do
      visit skills_character_path(character)
      within_skill_row(:unarmed_combat) { 2.times { click_button "+" } }
      within_skill_row(:sword_mastery) { click_button "+" }
    end

    it "resets all pending changes" do
      click_button "Reset"

      within_skill_row(:unarmed_combat) do
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+")
      end
      within_skill_row(:sword_mastery) do
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+")
      end
      within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
    end
  end

  describe "saving allocations" do
    before do
      visit skills_character_path(character)
      within_skill_row(:unarmed_combat) { click_button "+" }
    end

    it "saves skill allocation to database" do
      click_button "Save"

      expect(page).to have_content("Skills saved")
      character.reload
      expect(character.passive_skill_level(:unarmed_combat)).to eq(10)
      expect(character.combat_skill_points).to eq(9)
    end

    it "saves multiple pool allocations atomically" do
      within_skill_row(:self_healing) { click_button "+" }

      click_button "Save"
      expect(page).to have_content("Skills saved", wait: 5)

      character.reload
      expect(character.passive_skill_level(:unarmed_combat)).to eq(10)
      expect(character.passive_skill_level(:self_healing)).to eq(2)
      expect(character.combat_skill_points).to eq(9)
      expect(character.peace_skill_points).to eq(4)
    end
  end

  describe "dual pool system" do
    before { visit skills_character_path(character) }

    it "combat, magic, and resistance skills use combat points" do
      within_skill_row(:unarmed_combat) { click_button "+" }
      within_skill_row(:fire_magic) { click_button "+" }
      within_skill_row(:fire_magic_resistance) { click_button "+" }

      within(".nl-allocation-pool--combat") { expect(page).to have_content("7") }
      within(".nl-allocation-pool--peace") { expect(page).to have_content("5") }
    end

    it "peace/world skills use peace points" do
      within_skill_row(:self_healing) { click_button "+" }
      within_skill_row(:linguistics) { click_button "+" }

      within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
      within(".nl-allocation-pool--peace") { expect(page).to have_content("3") }
    end
  end

  describe "edge cases" do
    context "no points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 0, peace_skill_points: 0) }

      before { visit skills_character_path(character) }

      it "cannot add points when pool is empty" do
        within_skill_row(:unarmed_combat) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end

        within_skill_row(:self_healing) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end
      end
    end

    context "skill at max level" do
      before do
        character.passive_skills["unarmed_combat"] = 100
        character.save!
        visit skills_character_path(character)
      end

      it "shows MAX indicator and disables the add button" do
        within_skill_row(:unarmed_combat) do
          expect(page).to have_css(".nl-skill-gain", text: "MAX")
          expect(page).to have_button("+", disabled: true)
          expect(page).to have_content("[100/100]")
        end
      end
    end

    context "existing skill levels" do
      before do
        character.update!(passive_skills: {"unarmed_combat" => 50})
        visit skills_character_path(character)
      end

      it "shows existing level and current tier rate" do
        within_skill_row(:unarmed_combat) do
          expect(page).to have_content("[050/100]")
          expect(page).to have_css(".nl-skill-gain", text: "+6")
        end
      end

      it "cannot remove below existing level" do
        within_skill_row(:unarmed_combat) do
          click_button "−"
          expect(page).to have_content("[050/100]")
        end
      end
    end

    context "only combat points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 5, peace_skill_points: 0) }

      before { visit skills_character_path(character) }

      it "allows combat skill allocation and blocks peace skill allocation" do
        within_skill_row(:unarmed_combat) { click_button "+" }
        within_skill_row(:unarmed_combat) { expect(page).to have_content("[010/100]") }

        within_skill_row(:self_healing) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end
      end
    end

    context "only peace points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 0, peace_skill_points: 5) }

      before { visit skills_character_path(character) }

      it "blocks combat skill allocation and allows peace skill allocation" do
        within_skill_row(:unarmed_combat) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end

        within_skill_row(:self_healing) { click_button "+" }
        within_skill_row(:self_healing) { expect(page).to have_content("[002/100]") }
      end
    end
  end

  describe "authorization" do
    let(:other_user) { create(:user) }
    let(:other_character) { create(:character, user: other_user) }

    before do
      allow_any_instance_of(CharactersController).to receive(:current_character).and_call_original
    end

    it "redirects when accessing other user's character" do
      visit skills_character_path(other_character)
      expect(page).to have_current_path(root_path)
    end

    context "unauthenticated user" do
      before { Warden.test_reset! }

      it "redirects to login" do
        visit skills_character_path(character)
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  describe "Turbo integration" do
    before { visit skills_character_path(character) }

    it "form submits via Turbo" do
      within_skill_row(:unarmed_combat) { click_button "+" }
      click_button "Save"

      expect(page).to have_css("#skill-allocation")
      expect(page).to have_content("Skills saved")
    end
  end

  private

  def within_skill_row(skill_key, &block)
    within(".nl-skill-row:has([data-skill='#{skill_key}'])", &block)
  end
end
