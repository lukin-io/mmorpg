# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::ResistanceFormula do
  let(:rng) { Random.new(123) }
  let(:formula) { described_class.new(rng: rng) }

  # Helper to build a mock character with passive skills
  def build_character(passive_skills: {})
    skills = passive_skills
    obj = Object.new

    obj.define_singleton_method(:passive_skill_level) do |skill|
      skills[skill.to_sym].to_i
    end

    obj.define_singleton_method(:respond_to?) do |method, include_all = false|
      method == :passive_skill_level || super(method, include_all)
    end

    obj
  end

  # Helper to build a mock NPC with passive skills in metadata
  def build_npc(passive_skills: {})
    obj = Object.new
    meta = {"passive_skills" => passive_skills.transform_keys(&:to_s)}

    obj.define_singleton_method(:metadata) { meta }
    obj.define_singleton_method(:respond_to?) do |method, include_all = false|
      method == :metadata || super(method, include_all)
    end

    obj
  end

  describe "#call" do
    context "with physical damage" do
      let(:defender) { build_character(passive_skills: {physical_fortitude: 50}) }

      it "reduces damage based on physical_fortitude skill" do
        result = formula.call(defender: defender, damage: 100, element: :physical)

        # At level 50: 50/100 * 0.25 = 12.5% reduction
        expect(result[:reduction]).to be_within(0.01).of(0.125)
        expect(result[:final_damage]).to eq(88) # 100 * (1 - 0.125) = 87.5 -> 88
      end

      it "returns element and skill info" do
        result = formula.call(defender: defender, damage: 100, element: :physical)

        expect(result[:element]).to eq(:physical)
        expect(result[:resistance_skill]).to eq(:physical_fortitude)
        expect(result[:resistance_level]).to eq(50)
      end
    end

    context "with fire damage" do
      let(:defender) { build_character(passive_skills: {fire_resistance: 100}) }

      it "reduces damage based on fire_resistance skill" do
        result = formula.call(defender: defender, damage: 100, element: :fire)

        # At level 100: 100/100 * 0.40 = 40% reduction
        expect(result[:reduction]).to be_within(0.01).of(0.40)
        expect(result[:final_damage]).to eq(60)
      end
    end

    context "with cold/ice damage" do
      let(:defender) { build_character(passive_skills: {cold_resistance: 75}) }

      it "applies cold_resistance to ice element" do
        result = formula.call(defender: defender, damage: 100, element: :ice)

        # At level 75: 75/100 * 0.40 = 30% reduction
        expect(result[:reduction]).to be_within(0.01).of(0.30)
        expect(result[:final_damage]).to eq(70)
      end

      it "applies cold_resistance to water element" do
        result = formula.call(defender: defender, damage: 100, element: :water)

        expect(result[:resistance_skill]).to eq(:cold_resistance)
      end
    end

    context "with lightning damage" do
      let(:defender) { build_character(passive_skills: {lightning_resistance: 50}) }

      it "reduces damage based on lightning_resistance skill" do
        result = formula.call(defender: defender, damage: 100, element: :lightning)

        # At level 50: 50/100 * 0.40 = 20% reduction
        expect(result[:reduction]).to be_within(0.01).of(0.20)
        expect(result[:final_damage]).to eq(80)
      end

      it "applies lightning_resistance to air element" do
        result = formula.call(defender: defender, damage: 100, element: :air)

        expect(result[:resistance_skill]).to eq(:lightning_resistance)
      end
    end

    context "with no resistance skills" do
      let(:defender) { build_character(passive_skills: {}) }

      it "returns full damage" do
        result = formula.call(defender: defender, damage: 100, element: :fire)

        expect(result[:reduction]).to eq(0.0)
        expect(result[:final_damage]).to eq(100)
      end
    end

    context "with nil defender" do
      it "returns full damage" do
        result = formula.call(defender: nil, damage: 100, element: :fire)

        expect(result[:final_damage]).to eq(100)
        expect(result[:resistance_level]).to eq(0)
      end
    end

    context "with minimum damage rule" do
      let(:defender) { build_character(passive_skills: {fire_resistance: 100}) }

      it "enforces minimum 1 damage" do
        result = formula.call(defender: defender, damage: 1, element: :fire)

        expect(result[:final_damage]).to be >= 1
      end
    end

    context "with NPC defender" do
      let(:defender) { build_npc(passive_skills: {fire_resistance: 50}) }

      it "reads skills from metadata" do
        result = formula.call(defender: defender, damage: 100, element: :fire)

        expect(result[:resistance_level]).to eq(50)
        expect(result[:final_damage]).to be < 100
      end
    end
  end

  describe "#all_resistances" do
    let(:defender) do
      build_character(passive_skills: {
        fire_resistance: 40,
        cold_resistance: 30,
        lightning_resistance: 20,
        physical_fortitude: 50,
        spell_mastery: 10
      })
    end

    it "returns all resistance levels" do
      resistances = formula.all_resistances(defender)

      expect(resistances[:fire]).to eq(40)
      expect(resistances[:cold]).to eq(30)
      expect(resistances[:lightning]).to eq(20)
      expect(resistances[:physical]).to eq(50)
      expect(resistances[:arcane]).to eq(10)
    end
  end

  describe "#apply_multiple" do
    let(:defender) { build_character(passive_skills: {fire_resistance: 50, cold_resistance: 25}) }

    it "applies resistances to multiple damage instances" do
      damages = [
        {damage: 100, element: :fire},
        {damage: 50, element: :cold}
      ]

      results = formula.apply_multiple(defender: defender, damages: damages)

      expect(results.length).to eq(2)
      expect(results[0][:element]).to eq(:fire)
      expect(results[1][:element]).to eq(:cold)
    end
  end

  describe "edge cases" do
    it "handles unknown element by defaulting to physical_fortitude" do
      defender = build_character(passive_skills: {physical_fortitude: 50})
      result = formula.call(defender: defender, damage: 100, element: :unknown)

      expect(result[:resistance_skill]).to eq(:physical_fortitude)
    end

    it "handles string elements" do
      defender = build_character(passive_skills: {fire_resistance: 50})
      result = formula.call(defender: defender, damage: 100, element: "fire")

      expect(result[:element]).to eq(:fire)
      expect(result[:final_damage]).to be < 100
    end

    it "handles empty string element as physical" do
      defender = build_character(passive_skills: {physical_fortitude: 50})
      result = formula.call(defender: defender, damage: 100, element: "")

      expect(result[:element]).to eq(:physical)
    end
  end
end
