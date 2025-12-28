# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::CriticalFormula do
  let(:seed) { 12345 }
  let(:rng) { Random.new(seed) }
  let(:formula) { described_class.new(rng: rng) }

  def build_combatant(stats: {}, skills: {})
    combatant = double("Combatant")
    stat_block = double("StatBlock")

    allow(stat_block).to receive(:get) { |stat| stats[stat.to_sym] || 0 }
    allow(combatant).to receive(:stats).and_return(stat_block)
    allow(combatant).to receive(:respond_to?).with(anything).and_return(false)
    allow(combatant).to receive(:respond_to?).with(:stats).and_return(true)
    allow(combatant).to receive(:respond_to?).with(:passive_skill_level).and_return(true)
    allow(combatant).to receive(:passive_skill_level) { |skill| skills[skill.to_sym] || 0 }

    combatant
  end

  describe "#call" do
    context "with success cases" do
      it "calculates critical hit chance" do
        attacker = build_combatant(stats: {luck: 20, critical_chance: 5})
        defender = build_combatant(stats: {luck: 10})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result).to have_key(:critical)
        expect(result).to have_key(:multiplier)
        expect(result).to have_key(:roll)
        expect(result).to have_key(:chance)
      end

      it "returns deterministic results with same RNG seed" do
        attacker = build_combatant(stats: {luck: 20})
        defender = build_combatant(stats: {luck: 10})

        result1 = described_class.new(rng: Random.new(seed)).call(attacker: attacker, defender: defender)
        result2 = described_class.new(rng: Random.new(seed)).call(attacker: attacker, defender: defender)

        expect(result1[:critical]).to eq(result2[:critical])
        expect(result1[:roll]).to eq(result2[:roll])
      end

      it "applies multiplier only on critical" do
        attacker = build_combatant(stats: {luck: 50, critical_chance: 20})
        defender = build_combatant(stats: {luck: 0})

        # Find a critical hit
        100.times do |i|
          result = described_class.new(rng: Random.new(i)).call(attacker: attacker, defender: defender)

          if result[:critical]
            expect(result[:multiplier]).to be >= 1.5
            break
          end
        end

        # Find a non-critical
        100.times do |i|
          result = described_class.new(rng: Random.new(i + 500)).call(attacker: attacker, defender: defender)

          unless result[:critical]
            expect(result[:multiplier]).to eq(1.0)
            break
          end
        end
      end
    end

    context "with body part modifiers" do
      it "head attacks have higher crit chance" do
        attacker = build_combatant(stats: {luck: 20})
        defender = build_combatant(stats: {luck: 10})

        head_result = formula.call(attacker: attacker, defender: defender, body_part: "head")
        torso_result = described_class.new(rng: Random.new(seed)).call(
          attacker: attacker, defender: defender, body_part: "torso"
        )

        expect(head_result[:chance]).to be > torso_result[:chance]
      end

      it "head crits have extra damage multiplier" do
        attacker = build_combatant(stats: {luck: 50})
        defender = build_combatant(stats: {luck: 0})

        # Find a head crit
        100.times do |i|
          result = described_class.new(rng: Random.new(i)).call(
            attacker: attacker, defender: defender, body_part: "head"
          )

          if result[:critical]
            expect(result[:multiplier]).to be >= 1.7 # 1.5 base + 0.2 head bonus
            break
          end
        end
      end
    end

    context "with action type modifiers" do
      it "aimed attacks have higher crit chance" do
        attacker = build_combatant(stats: {luck: 20})
        defender = build_combatant(stats: {luck: 10})

        simple_result = formula.call(attacker: attacker, defender: defender, action_key: "simple")
        aimed_result = described_class.new(rng: Random.new(seed)).call(
          attacker: attacker, defender: defender, action_key: "aimed"
        )

        expect(aimed_result[:chance]).to be > simple_result[:chance]
      end
    end

    context "with edge cases" do
      it "clamps critical chance to minimum 1%" do
        attacker = build_combatant(stats: {luck: 0})
        defender = build_combatant(stats: {luck: 100})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result[:chance]).to be >= 1.0
      end

      it "clamps critical chance to maximum 50%" do
        attacker = build_combatant(stats: {luck: 100, critical_chance: 100})
        defender = build_combatant(stats: {luck: 0})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result[:chance]).to be <= 50.0
      end

      it "handles nil attacker" do
        defender = build_combatant(stats: {luck: 10})

        result = formula.call(attacker: nil, defender: defender)

        expect(result).to be_a(Hash)
        expect(result[:chance]).to be >= 1.0
      end
    end

    context "with passive skills" do
      it "applies critical_strikes skill bonus" do
        attacker = build_combatant(stats: {luck: 20}, skills: {critical_strikes: 50})
        defender = build_combatant(stats: {luck: 10})

        result = formula.call(attacker: attacker, defender: defender)

        # 50 skill should add ~7.5% (50/100 * 15)
        expect(result[:chance]).to be > 16 # Base 10 + luck bonus + skill
      end
    end
  end

  describe "#multiplier_for" do
    it "calculates multiplier without rolling" do
      attacker = build_combatant(stats: {luck: 20})

      multiplier = formula.multiplier_for(attacker: attacker)

      expect(multiplier).to be >= 1.5
    end

    it "adds head bonus" do
      attacker = build_combatant(stats: {luck: 20})

      head_mult = formula.multiplier_for(attacker: attacker, body_part: "head")
      torso_mult = formula.multiplier_for(attacker: attacker, body_part: "torso")

      expect(head_mult).to be > torso_mult
    end

    it "applies critical_strikes skill to multiplier" do
      attacker_no_skill = build_combatant(stats: {luck: 20}, skills: {})
      attacker_with_skill = build_combatant(stats: {luck: 20}, skills: {critical_strikes: 100})

      mult_no_skill = formula.multiplier_for(attacker: attacker_no_skill)
      mult_with_skill = formula.multiplier_for(attacker: attacker_with_skill)

      expect(mult_with_skill).to be > mult_no_skill
    end
  end
end
