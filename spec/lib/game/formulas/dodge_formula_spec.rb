# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::DodgeFormula do
  let(:seed) { 12345 }
  let(:rng) { Random.new(seed) }
  let(:formula) { described_class.new(rng: rng) }

  def build_combatant(stats: {}, skills: {}, armor_type: nil)
    combatant = double("Combatant")
    stat_block = double("StatBlock")

    allow(stat_block).to receive(:get) { |stat| stats[stat.to_sym] || 0 }
    allow(combatant).to receive(:stats).and_return(stat_block)
    allow(combatant).to receive(:respond_to?).with(anything).and_return(false)
    allow(combatant).to receive(:respond_to?).with(:stats).and_return(true)
    allow(combatant).to receive(:respond_to?).with(:passive_skill_level).and_return(true)
    allow(combatant).to receive(:respond_to?).with(:armor_type).and_return(!armor_type.nil?)
    allow(combatant).to receive(:passive_skill_level) { |skill| skills[skill.to_sym] || 0 }
    allow(combatant).to receive(:armor_type).and_return(armor_type)

    combatant
  end

  describe "#call" do
    context "with success cases" do
      it "calculates dodge chance" do
        defender = build_combatant(stats: {agility: 30, evasion: 20, luck: 10})
        attacker = build_combatant(stats: {accuracy: 15, dexterity: 10})

        result = formula.call(defender: defender, attacker: attacker)

        expect(result).to have_key(:dodged)
        expect(result).to have_key(:roll)
        expect(result).to have_key(:chance)
      end

      it "returns deterministic results with same RNG seed" do
        defender = build_combatant(stats: {agility: 30})
        attacker = build_combatant(stats: {accuracy: 15})

        result1 = described_class.new(rng: Random.new(seed)).call(defender: defender, attacker: attacker)
        result2 = described_class.new(rng: Random.new(seed)).call(defender: defender, attacker: attacker)

        expect(result1[:dodged]).to eq(result2[:dodged])
        expect(result1[:roll]).to eq(result2[:roll])
      end

      it "high agility increases dodge chance" do
        low_agi = build_combatant(stats: {agility: 10})
        high_agi = build_combatant(stats: {agility: 50})
        attacker = build_combatant(stats: {accuracy: 10})

        low_result = formula.call(defender: low_agi, attacker: attacker)
        high_result = described_class.new(rng: Random.new(seed)).call(defender: high_agi, attacker: attacker)

        expect(high_result[:chance]).to be > low_result[:chance]
      end
    end

    context "with body part modifiers" do
      it "head attacks are easier to dodge" do
        defender = build_combatant(stats: {agility: 30})
        attacker = build_combatant(stats: {accuracy: 15})

        head_result = formula.call(defender: defender, attacker: attacker, body_part: "head")
        legs_result = described_class.new(rng: Random.new(seed)).call(
          defender: defender, attacker: attacker, body_part: "legs"
        )

        expect(head_result[:chance]).to be > legs_result[:chance]
      end
    end

    context "with action type modifiers" do
      it "aimed attacks are harder to dodge" do
        defender = build_combatant(stats: {agility: 30})
        attacker = build_combatant(stats: {accuracy: 15})

        simple_result = formula.call(defender: defender, attacker: attacker, action_key: "simple")
        aimed_result = described_class.new(rng: Random.new(seed)).call(
          defender: defender, attacker: attacker, action_key: "aimed"
        )

        expect(aimed_result[:chance]).to be < simple_result[:chance]
      end

      it "power attacks are easier to dodge" do
        defender = build_combatant(stats: {agility: 30})
        attacker = build_combatant(stats: {accuracy: 15})

        simple_result = formula.call(defender: defender, attacker: attacker, action_key: "simple")
        power_result = described_class.new(rng: Random.new(seed)).call(
          defender: defender, attacker: attacker, action_key: "power"
        )

        expect(power_result[:chance]).to be > simple_result[:chance]
      end
    end

    context "with edge cases" do
      it "clamps dodge chance to maximum 40%" do
        defender = build_combatant(stats: {agility: 100, evasion: 100, luck: 50}, skills: {evasion: 100})
        attacker = build_combatant(stats: {accuracy: 0})

        result = formula.call(defender: defender, attacker: attacker)

        expect(result[:chance]).to be <= 40.0
      end

      it "clamps dodge chance to minimum 0%" do
        defender = build_combatant(stats: {agility: 0})
        attacker = build_combatant(stats: {accuracy: 100, dexterity: 100})

        result = formula.call(defender: defender, attacker: attacker)

        expect(result[:chance]).to be >= 0.0
      end

      it "handles nil defender" do
        attacker = build_combatant(stats: {accuracy: 15})

        result = formula.call(defender: nil, attacker: attacker)

        expect(result).to be_a(Hash)
        expect(result[:chance]).to be >= 0.0 # Clamped at minimum
      end
    end

    context "with equipment bonuses" do
      it "light armor increases dodge chance" do
        light_armor = build_combatant(stats: {agility: 30}, armor_type: "light")
        heavy_armor = build_combatant(stats: {agility: 30}, armor_type: "heavy")
        attacker = build_combatant(stats: {accuracy: 15})

        light_result = formula.call(defender: light_armor, attacker: attacker)
        heavy_result = described_class.new(rng: Random.new(seed)).call(
          defender: heavy_armor, attacker: attacker
        )

        expect(light_result[:chance]).to be > heavy_result[:chance]
      end
    end

    context "with passive skills" do
      it "evasion skill increases dodge chance" do
        no_skill = build_combatant(stats: {agility: 30}, skills: {})
        with_skill = build_combatant(stats: {agility: 30}, skills: {evasion: 50})
        attacker = build_combatant(stats: {accuracy: 15})

        no_skill_result = formula.call(defender: no_skill, attacker: attacker)
        with_skill_result = described_class.new(rng: Random.new(seed)).call(
          defender: with_skill, attacker: attacker
        )

        expect(with_skill_result[:chance]).to be > no_skill_result[:chance]
      end

      it "attacker melee skill reduces dodge chance" do
        defender = build_combatant(stats: {agility: 30})
        no_skill = build_combatant(stats: {accuracy: 15}, skills: {})
        with_skill = build_combatant(stats: {accuracy: 15}, skills: {melee_combat: 50})

        no_skill_result = formula.call(defender: defender, attacker: no_skill)
        with_skill_result = described_class.new(rng: Random.new(seed)).call(
          defender: defender, attacker: with_skill
        )

        expect(with_skill_result[:chance]).to be < no_skill_result[:chance]
      end
    end
  end

  describe "#dodge_chance_for" do
    it "returns raw dodge chance without rolling" do
      defender = build_combatant(stats: {agility: 30, evasion: 20})

      chance = formula.dodge_chance_for(defender: defender)

      expect(chance).to be_a(Float)
      expect(chance).to be > 5.0 # More than base
    end

    it "includes evasion skill bonus" do
      no_skill = build_combatant(stats: {agility: 30}, skills: {})
      with_skill = build_combatant(stats: {agility: 30}, skills: {evasion: 100})

      no_skill_chance = formula.dodge_chance_for(defender: no_skill)
      with_skill_chance = formula.dodge_chance_for(defender: with_skill)

      expect(with_skill_chance).to be > no_skill_chance
    end
  end
end
