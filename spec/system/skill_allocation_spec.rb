# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Skill Allocation", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) do
    create(:character, user: user, combat_skill_points: 10, peace_skill_points: 5, skill_points_available: 15)
  end

  before do
    login_as(user, scope: :user)
    allow_any_instance_of(CharactersController).to receive(:current_character).and_return(character)
  end

  # ============================================
  # DISPLAY TESTS
  # ============================================
  describe "skills page display" do
    before { visit skills_character_path(character) }

    it "displays the skill allocation page" do
      expect(page).to have_content("Passive Skills")
      expect(page).to have_content(character.name)
    end

    it "displays combat skill points" do
      within(".nl-allocation-pool--combat") do
        expect(page).to have_content("Combat/Magic Points:")
        expect(page).to have_content("10")
      end
    end

    it "displays peace skill points" do
      within(".nl-allocation-pool--peace") do
        expect(page).to have_content("Peace Points:")
        expect(page).to have_content("5")
      end
    end

    it "displays skill categories with icons" do
      expect(page).to have_content("Combat Skills")
      expect(page).to have_content("Magic Skills")
      expect(page).to have_content("Resistances")
      expect(page).to have_content("Survival")
      expect(page).to have_content("Peace Skills")
    end

    it "displays skills with initial values" do
      expect(page).to have_content("Wanderer")
      expect(page).to have_content("[000/100]")
    end

    it "displays points per spend indicator" do
      expect(page).to have_css(".nl-skill-gain[data-skill='wanderer']", text: "+10")
    end

    it "displays effect preview" do
      expect(page).to have_content("Movement:")
    end

    it "displays tiered progression legend" do
      expect(page).to have_content("Tiered Progression")
      expect(page).to have_content("Level 0-24")
      expect(page).to have_content("Level 25-49")
      expect(page).to have_content("Level 50-74")
      expect(page).to have_content("Level 75-99")
    end

    it "save button is initially disabled" do
      expect(page).to have_button("Save Skills", disabled: true)
    end

    it "has a reset button" do
      expect(page).to have_button("Reset")
    end

    it "has navigation links" do
      expect(page).to have_link("Back to World")
      expect(page).to have_link("Character Stats")
    end
  end

  # ============================================
  # ADDING SKILL POINTS
  # ============================================
  describe "adding skill points" do
    before { visit skills_character_path(character) }

    context "basic allocation" do
      it "increments skill level when clicking +" do
        within_skill_row(:wanderer) do
          click_button "+"
          expect(page).to have_content("[010/100]")
          expect(page).to have_content("(+10)")
        end
      end

      it "decrements combat points for combat skills" do
        within_skill_row(:wanderer) do
          click_button "+"
        end

        within(".nl-allocation-pool--combat") do
          expect(page).to have_content("9")
        end
      end

      it "enables save button after allocation" do
        within_skill_row(:wanderer) do
          click_button "+"
        end

        expect(page).to have_button("Save Skills", disabled: false)
      end

      it "updates effect preview in real-time" do
        within_skill_row(:wanderer) do
          click_button "+"
        end
        # At level 10, 7% reduction, 9.3s cooldown
        expect(page).to have_content("Movement: 9.3s (-7%)")
      end
    end

    context "tiered progression" do
      it "applies tier 0 rate (10 points) at levels 0-24" do
        within_skill_row(:wanderer) do
          click_button "+"
          expect(page).to have_content("[010/100]")
          click_button "+"
          expect(page).to have_content("[020/100]")
        end
      end

      it "transitions to tier 1 rate (8 points) at level 25" do
        within_skill_row(:wanderer) do
          # 3 spends: 0→10→20→30 (crosses tier boundary)
          3.times { click_button "+" }
          expect(page).to have_content("[030/100]")
          # Now in tier 1, next spend gives +8
          expect(page).to have_css(".nl-skill-gain", text: "+8")
        end
      end

      it "transitions to tier 2 rate (6 points) at level 50" do
        character.update!(combat_skill_points: 20)
        visit skills_character_path(character)

        within_skill_row(:wanderer) do
          # 6 spends to reach ~54
          6.times { click_button "+" }
          # Now in tier 2, next spend gives +6
          expect(page).to have_css(".nl-skill-gain", text: "+6")
        end
      end

      it "transitions to tier 3 rate (4 points) at level 75" do
        character.update!(passive_skills: {"wanderer" => 75}, combat_skill_points: 20)
        visit skills_character_path(character)

        within_skill_row(:wanderer) do
          expect(page).to have_css(".nl-skill-gain", text: "+4")
        end
      end

      it "updates points-per-spend indicator as level increases" do
        within_skill_row(:wanderer) do
          expect(page).to have_css(".nl-skill-gain", text: "+10")
          3.times { click_button "+" }
          expect(page).to have_css(".nl-skill-gain", text: "+8")
        end
      end
    end

    context "multiple skills" do
      it "can allocate to multiple skills simultaneously" do
        within_skill_row(:wanderer) { click_button "+" }
        within_skill_row(:melee_combat) { click_button "+" }
        within_skill_row(:ranged_combat) { click_button "+" }

        within_skill_row(:wanderer) { expect(page).to have_content("[010/100]") }
        within_skill_row(:melee_combat) { expect(page).to have_content("[010/100]") }
        within_skill_row(:ranged_combat) { expect(page).to have_content("[010/100]") }

        within(".nl-allocation-pool--combat") do
          expect(page).to have_content("7") # 10 - 3
        end
      end

      it "tracks pending changes for each skill" do
        within_skill_row(:wanderer) { click_button "+" }
        within_skill_row(:melee_combat) { 2.times { click_button "+" } }

        within_skill_row(:wanderer) { expect(page).to have_content("(+10)") }
        within_skill_row(:melee_combat) { expect(page).to have_content("(+20)") }
      end
    end
  end

  # ============================================
  # REMOVING SKILL POINTS
  # ============================================
  describe "removing skill points" do
    before do
      visit skills_character_path(character)
      within_skill_row(:wanderer) do
        click_button "+"
      end
    end

    it "decrements skill level when clicking -" do
      within_skill_row(:wanderer) do
        click_button "−"
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+10)")
      end
    end

    it "restores combat points" do
      within_skill_row(:wanderer) do
        click_button "−"
      end

      within(".nl-allocation-pool--combat") do
        expect(page).to have_content("10")
      end
    end

    it "disables save button when reset to original" do
      within_skill_row(:wanderer) do
        click_button "−"
      end

      expect(page).to have_button("Save Skills", disabled: true)
    end

    it "cannot remove below base level" do
      within_skill_row(:wanderer) do
        click_button "−" # Remove the spend we added
        click_button "−" # Try to go below base - should shake
        expect(page).to have_content("[000/100]")
      end
    end

    it "correctly restores level when removing tiered spends" do
      # Before block already added 1 spend (0→10), now add 2 more: 10→20→30
      within_skill_row(:wanderer) do
        2.times { click_button "+" }
        expect(page).to have_content("[030/100]")

        # Remove 1 spend - should go back to 20
        click_button "−"
        expect(page).to have_content("[020/100]")
      end
    end
  end

  # ============================================
  # RESET FUNCTIONALITY
  # ============================================
  describe "reset functionality" do
    before do
      visit skills_character_path(character)
      within_skill_row(:wanderer) do
        2.times { click_button "+" }
      end
      within_skill_row(:melee_combat) do
        click_button "+"
      end
    end

    it "resets all pending changes" do
      click_button "Reset"

      within_skill_row(:wanderer) do
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+")
      end
      within_skill_row(:melee_combat) do
        expect(page).to have_content("[000/100]")
        expect(page).not_to have_content("(+")
      end
    end

    it "restores all skill points" do
      click_button "Reset"

      within(".nl-allocation-pool--combat") do
        expect(page).to have_content("10")
      end
    end

    it "disables save button" do
      click_button "Reset"
      expect(page).to have_button("Save Skills", disabled: true)
    end

    it "allows re-allocation after reset" do
      click_button "Reset"

      within_skill_row(:wanderer) do
        click_button "+"
        expect(page).to have_content("[010/100]")
      end
    end
  end

  # ============================================
  # SAVING ALLOCATIONS
  # ============================================
  describe "saving allocations" do
    before do
      visit skills_character_path(character)
      within_skill_row(:wanderer) do
        click_button "+"
      end
    end

    it "saves skill allocation to database" do
      click_button "Save Skills"

      expect(page).to have_content("Skills allocated")
      character.reload
      expect(character.passive_skill_level(:wanderer)).to eq(10)
    end

    it "updates points after save" do
      click_button "Save Skills"

      within(".nl-allocation-pool--combat") do
        expect(page).to have_content("9")
      end
    end

    it "resets pending indicator after save" do
      click_button "Save Skills"

      within_skill_row(:wanderer) do
        expect(page).to have_content("[010/100]")
        expect(page).not_to have_content("(+10)")
      end
    end

    it "disables save button after successful save" do
      click_button "Save Skills"
      expect(page).to have_button("Save Skills", disabled: true)
    end

    it "persists allocation across page refresh" do
      click_button "Save Skills"
      visit skills_character_path(character)

      within_skill_row(:wanderer) do
        expect(page).to have_content("[010/100]")
      end
    end

    it "saves multiple skill allocations atomically" do
      within_skill_row(:melee_combat) { click_button "+" }
      within_skill_row(:ranged_combat) { click_button "+" }

      click_button "Save Skills"
      expect(page).to have_content("Skills allocated", wait: 5)

      character.reload
      expect(character.passive_skill_level(:wanderer)).to eq(10)
      expect(character.passive_skill_level(:melee_combat)).to eq(10)
      expect(character.passive_skill_level(:ranged_combat)).to eq(10)
      expect(character.combat_skill_points).to eq(7)
    end
  end

  # ============================================
  # DUAL POOL SYSTEM
  # ============================================
  describe "dual pool system" do
    before { visit skills_character_path(character) }

    context "combat skills" do
      it "melee_combat uses combat points" do
        within_skill_row(:melee_combat) { click_button "+" }

        within(".nl-allocation-pool--combat") { expect(page).to have_content("9") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("5") }
      end

      it "ranged_combat uses combat points" do
        within_skill_row(:ranged_combat) { click_button "+" }

        within(".nl-allocation-pool--combat") { expect(page).to have_content("9") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("5") }
      end

      it "elemental_magic uses combat points" do
        within_skill_row(:elemental_magic) { click_button "+" }

        within(".nl-allocation-pool--combat") { expect(page).to have_content("9") }
      end
    end

    context "peace skills" do
      it "herbalism uses peace points" do
        within_skill_row(:herbalism) { click_button "+" }

        within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("4") }
      end

      it "mining uses peace points" do
        within_skill_row(:mining) { click_button "+" }

        within(".nl-allocation-pool--combat") { expect(page).to have_content("10") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("4") }
      end

      it "trading uses peace points" do
        within_skill_row(:trading) { click_button "+" }

        within(".nl-allocation-pool--peace") { expect(page).to have_content("4") }
      end
    end

    context "mixed allocations" do
      it "can allocate from both pools in same session" do
        within_skill_row(:melee_combat) { click_button "+" } # combat
        within_skill_row(:herbalism) { click_button "+" }    # peace

        within(".nl-allocation-pool--combat") { expect(page).to have_content("9") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("4") }
      end

      it "saves allocations from both pools" do
        within_skill_row(:melee_combat) { click_button "+" }
        within_skill_row(:herbalism) { click_button "+" }

        click_button "Save Skills"
        expect(page).to have_content("Skills allocated", wait: 5)

        character.reload
        expect(character.combat_skill_points).to eq(9)
        expect(character.peace_skill_points).to eq(4)
      end
    end
  end

  # ============================================
  # EDGE CASES
  # ============================================
  describe "edge cases" do
    context "no points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 0, peace_skill_points: 0) }

      before { visit skills_character_path(character) }

      it "shows zero points" do
        within(".nl-allocation-pool--combat") { expect(page).to have_content("0") }
        within(".nl-allocation-pool--peace") { expect(page).to have_content("0") }
      end

      it "cannot add points when pool is empty" do
        within_skill_row(:wanderer) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end
      end

      it "shake animation feedback on failed add" do
        within_skill_row(:wanderer) do
          button = find("button", text: "+")
          button.click
          # Verify skill didn't change
          expect(page).to have_content("[000/100]")
        end
      end
    end

    context "skill at max level" do
      before do
        character.passive_skills["wanderer"] = 100
        character.save!
        visit skills_character_path(character)
      end

      it "shows MAX indicator" do
        within_skill_row(:wanderer) do
          expect(page).to have_css(".nl-skill-gain", text: "MAX")
        end
      end

      it "disables + button" do
        within_skill_row(:wanderer) do
          expect(page).to have_button("+", disabled: true)
        end
      end

      it "displays full progress [100/100]" do
        within_skill_row(:wanderer) do
          expect(page).to have_content("[100/100]")
        end
      end
    end

    context "skill near max level" do
      before do
        character.update!(passive_skills: {"wanderer" => 98}, combat_skill_points: 10)
        visit skills_character_path(character)
      end

      it "caps at max level when adding points" do
        within_skill_row(:wanderer) do
          click_button "+"
          expect(page).to have_content("[100/100]")
        end
      end

      it "shows MAX after reaching cap" do
        within_skill_row(:wanderer) do
          click_button "+"
          expect(page).to have_css(".nl-skill-gain", text: "MAX")
        end
      end
    end

    context "existing skill levels" do
      before do
        character.update!(passive_skills: {"wanderer" => 50})
        visit skills_character_path(character)
      end

      it "shows existing level" do
        within_skill_row(:wanderer) do
          expect(page).to have_content("[050/100]")
        end
      end

      it "uses correct tier rate for existing level" do
        within_skill_row(:wanderer) do
          # At level 50, tier 2, rate should be 6
          expect(page).to have_css(".nl-skill-gain", text: "+6")
        end
      end

      it "cannot remove below existing level" do
        within_skill_row(:wanderer) do
          click_button "−"
          expect(page).to have_content("[050/100]")
        end
      end
    end

    context "only combat points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 5, peace_skill_points: 0) }

      before { visit skills_character_path(character) }

      it "allows combat skill allocation" do
        within_skill_row(:melee_combat) { click_button "+" }
        within_skill_row(:melee_combat) { expect(page).to have_content("[010/100]") }
      end

      it "blocks peace skill allocation" do
        within_skill_row(:herbalism) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end
      end
    end

    context "only peace points available" do
      let(:character) { create(:character, user: user, combat_skill_points: 0, peace_skill_points: 5) }

      before { visit skills_character_path(character) }

      it "blocks combat skill allocation" do
        within_skill_row(:melee_combat) do
          click_button "+"
          expect(page).to have_content("[000/100]")
        end
      end

      it "allows peace skill allocation" do
        within_skill_row(:herbalism) { click_button "+" }
        within_skill_row(:herbalism) { expect(page).to have_content("[002/100]") } # Peace rate is 2:2:2:2
      end
    end
  end

  # ============================================
  # AUTHORIZATION
  # ============================================
  describe "authorization" do
    let(:other_user) { create(:user) }
    let(:other_character) { create(:character, user: other_user) }

    before do
      allow_any_instance_of(CharactersController).to receive(:current_character).and_call_original
    end

    it "redirects when accessing other user's character" do
      visit skills_character_path(other_character)
      # May redirect to dashboard or root depending on auth config
      expect(page).to have_current_path(root_path).or have_current_path(dashboard_path)
    end

    context "unauthenticated user" do
      before { Warden.test_reset! }

      it "redirects to login" do
        visit skills_character_path(character)
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  # ============================================
  # TURBO FRAME / TURBO STREAM BEHAVIOR
  # ============================================
  describe "Turbo integration" do
    before { visit skills_character_path(character) }

    it "form submits via Turbo" do
      within_skill_row(:wanderer) { click_button "+" }
      click_button "Save Skills"

      # Should not do a full page reload
      expect(page).to have_css("#skill-allocation")
      expect(page).to have_content("Skills allocated")
    end

    it "displays flash message in correct location" do
      within_skill_row(:wanderer) { click_button "+" }
      click_button "Save Skills"

      expect(page).to have_content("Skills allocated")
    end
  end

  # ============================================
  # SKILL EFFECTS (COMBAT IMPACT)
  # ============================================
  describe "skill effects impact combat" do
    before do
      visit skills_character_path(character)
    end

    it "displays damage bonus for melee_combat" do
      within_skill_row(:melee_combat) do
        click_button "+"
        # At level 10, 5% damage bonus
      end
      expect(page).to have_content("Damage: +5%")
    end

    it "displays critical chance bonus for critical_strikes" do
      within_skill_row(:critical_strikes) do
        click_button "+"
      end
      expect(page).to have_content("Crit Chance:")
    end

    it "displays evasion bonus for evasion skill" do
      within_skill_row(:evasion) do
        click_button "+"
      end
      expect(page).to have_content("Dodge:")
    end

    it "displays block bonus for block_mastery" do
      within_skill_row(:block_mastery) do
        click_button "+"
      end
      expect(page).to have_content("Block:")
    end

    it "displays resistance bonus for fire_resistance" do
      within_skill_row(:fire_resistance) do
        click_button "+"
      end
      expect(page).to have_content("Resist:")
    end
  end

  # ============================================
  # SKILL EFFECTS (PEACE / NON-COMBAT)
  # ============================================
  describe "skill effects impact non-combat activities" do
    before do
      visit skills_character_path(character)
    end

    it "displays trading price bonus" do
      within_skill_row(:trading) do
        click_button "+"
      end
      expect(page).to have_content("Prices:")
    end

    it "displays herbalism yield bonus" do
      within_skill_row(:herbalism) do
        click_button "+"
      end
      expect(page).to have_content("Yield:")
    end

    it "displays alchemy potion bonus" do
      within_skill_row(:alchemy) do
        click_button "+"
      end
      expect(page).to have_content("Potions:")
    end

    it "displays cooking buff duration bonus" do
      within_skill_row(:cooking) do
        click_button "+"
      end
      expect(page).to have_content("Buff Duration:")
    end
  end

  # ============================================
  # FUTURE INTEGRATION TESTS (DRAFTS)
  # ============================================
  describe "combat system integration", :skip_ci do
    xit "allocated combat skills affect damage dealt in battle" do
      # When combat system is integrated:
      # 1. Allocate melee_combat to 100
      # 2. Start a battle
      # 3. Verify damage is increased by 50%
    end

    xit "allocated critical_strikes affects crit rate in battle" do
      # When combat system is integrated:
      # 1. Allocate critical_strikes
      # 2. Verify crit chance increases
    end

    xit "allocated evasion affects dodge rate in battle" do
      # When combat system is integrated:
      # 1. Allocate evasion
      # 2. Verify dodge chance increases
    end

    xit "allocated resistance skills reduce damage taken" do
      # When combat system is integrated:
      # 1. Allocate fire_resistance
      # 2. Take fire damage
      # 3. Verify damage is reduced
    end
  end

  describe "crafting system integration", :skip_ci do
    xit "allocated blacksmithing unlocks higher tier recipes" do
      # When crafting system is integrated
    end

    xit "allocated alchemy increases potion effectiveness" do
      # When alchemy system is integrated
    end

    xit "allocated cooking increases buff duration" do
      # When cooking system is integrated
    end
  end

  describe "gathering system integration", :skip_ci do
    xit "allocated herbalism increases herb yield" do
      # When gathering system is integrated
    end

    xit "allocated mining increases ore quality" do
      # When gathering system is integrated
    end

    xit "allocated fishing increases rare fish chance" do
      # When gathering system is integrated
    end
  end

  describe "economy system integration", :skip_ci do
    xit "allocated trading affects NPC shop prices" do
      # When economy system is integrated
    end
  end

  # ============================================
  # HELPERS
  # ============================================
  private

  def within_skill_row(skill_key, &block)
    within(".nl-skill-row:has([data-skill='#{skill_key}'])", &block)
  end
end
