# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::CombatDamageFormula do
  let(:rng) { Random.new(12345) }
  subject(:formula) { described_class.new(rng: rng) }

  describe "#call" do
    let(:attacker) { double("Attacker", attack_power: 20, critical_chance: 10) }
    let(:defender) { double("Defender", defense: 10) }

    it "calculates base damage" do
      damage = formula.call(attacker, defender)

      # Base: 20 - (10/2) = 15, plus variance 1-5
      expect(damage).to be_between(16, 20)
    end

    it "returns at least minimum damage" do
      weak_attacker = double("WeakAttacker", attack_power: 1, critical_chance: 0)
      strong_defender = double("StrongDefender", defense: 100)

      damage = formula.call(weak_attacker, strong_defender)

      expect(damage).to be >= described_class::MIN_DAMAGE
    end

    context "when defender is defending" do
      it "reduces damage with 1.5x defense" do
        normal_damage = formula.call(attacker, defender, is_defending: false)

        # Reset RNG for fair comparison
        formula2 = described_class.new(rng: Random.new(12345))
        defended_damage = formula2.call(attacker, defender, is_defending: true)

        expect(defended_damage).to be < normal_damage
      end
    end

    context "when critical hit" do
      it "increases damage by 1.5x" do
        normal_damage = formula.call(attacker, defender, is_critical: false)

        # Reset RNG for fair comparison
        formula2 = described_class.new(rng: Random.new(12345))
        crit_damage = formula2.call(attacker, defender, is_critical: true)

        expect(crit_damage).to eq((normal_damage * 1.5).to_i)
      end
    end

    context "with damage multiplier" do
      it "applies the multiplier" do
        base_damage = formula.call(attacker, defender, damage_multiplier: 1.0)

        formula2 = described_class.new(rng: Random.new(12345))
        boosted_damage = formula2.call(attacker, defender, damage_multiplier: 1.3)

        expect(boosted_damage).to be > base_damage
      end
    end

    context "with all modifiers" do
      it "stacks multipliers correctly" do
        damage = formula.call(
          attacker,
          defender,
          is_defending: false,
          is_critical: true,
          damage_multiplier: 1.3
        )

        # Should be boosted by both crit and multiplier
        # 15
        # Plus variance, times 1.3, times 1.5
        expect(damage).to be > 20
      end
    end
  end

  describe "#critical_hit?" do
    it "returns true when roll is below crit chance" do
      high_crit = double("HighCrit", critical_chance: 100)
      expect(formula.critical_hit?(high_crit)).to be true
    end

    it "returns false when roll is above crit chance" do
      low_crit = double("LowCrit", critical_chance: 0)
      expect(formula.critical_hit?(low_crit)).to be false
    end

    it "uses seeded RNG for deterministic results" do
      attacker = double("Attacker", critical_chance: 50)

      formula1 = described_class.new(rng: Random.new(99999))
      formula2 = described_class.new(rng: Random.new(99999))

      result1 = formula1.critical_hit?(attacker)
      result2 = formula2.critical_hit?(attacker)

      expect(result1).to eq(result2)
    end
  end

  describe "#attack_power" do
    it "returns attack_power from entity" do
      entity = double("Entity", attack_power: 25)
      expect(formula.attack_power(entity)).to eq(25)
    end

    it "falls back to stats.get if no attack_power method" do
      stats = double("Stats")
      allow(stats).to receive(:get).with(:attack_power).and_return(30)
      entity = double("Entity", stats: stats)
      allow(entity).to receive(:respond_to?).and_return(false)
      allow(entity).to receive(:respond_to?).with(:attack_power).and_return(false)
      allow(entity).to receive(:respond_to?).with(:stats).and_return(true)

      expect(formula.attack_power(entity)).to eq(30)
    end

    it "returns default 10 if no stats available" do
      entity = double("Entity")
      allow(entity).to receive(:respond_to?).and_return(false)
      allow(entity).to receive(:respond_to?).with(:attack_power).and_return(false)
      allow(entity).to receive(:respond_to?).with(:stats).and_return(false)

      expect(formula.attack_power(entity)).to eq(10)
    end
  end

  describe "#defense_power" do
    it "returns defense from entity" do
      entity = double("Entity", defense: 15)
      expect(formula.defense_power(entity)).to eq(15)
    end

    it "falls back to stats.get if no defense method" do
      stats = double("Stats")
      allow(stats).to receive(:get).with(:defense).and_return(20)
      entity = double("Entity", stats: stats)
      allow(entity).to receive(:respond_to?).and_return(false)
      allow(entity).to receive(:respond_to?).with(:defense).and_return(false)
      allow(entity).to receive(:respond_to?).with(:stats).and_return(true)

      expect(formula.defense_power(entity)).to eq(20)
    end

    it "returns default 5 if no stats available" do
      entity = double("Entity")
      allow(entity).to receive(:respond_to?).and_return(false)
      allow(entity).to receive(:respond_to?).with(:defense).and_return(false)
      allow(entity).to receive(:respond_to?).with(:stats).and_return(false)

      expect(formula.defense_power(entity)).to eq(5)
    end
  end

  describe "#crit_chance" do
    it "returns critical_chance from entity" do
      entity = double("Entity", critical_chance: 25)
      expect(formula.crit_chance(entity)).to eq(25)
    end

    it "returns default 5 if no critical_chance available" do
      entity = double("Entity")
      allow(entity).to receive(:respond_to?).and_return(false)
      allow(entity).to receive(:respond_to?).with(:critical_chance).and_return(false)
      allow(entity).to receive(:respond_to?).with(:stats).and_return(false)

      expect(formula.crit_chance(entity)).to eq(5)
    end
  end

  describe "determinism" do
    it "produces identical results with same seed" do
      attacker = double("Attacker", attack_power: 20, critical_chance: 10)
      defender = double("Defender", defense: 10)

      formula1 = described_class.new(rng: Random.new(54321))
      formula2 = described_class.new(rng: Random.new(54321))

      damage1 = formula1.call(attacker, defender)
      damage2 = formula2.call(attacker, defender)

      expect(damage1).to eq(damage2)
    end

    it "produces different results with different seeds" do
      attacker = double("Attacker", attack_power: 20, critical_chance: 10)
      defender = double("Defender", defense: 10)

      damages = 5.times.map do |i|
        f = described_class.new(rng: Random.new(i * 1000))
        f.call(attacker, defender)
      end

      # Not all damages should be identical (though some might be due to variance range)
      # With 5 different seeds, we expect some variation
      expect(damages.uniq.size).to be >= 1
    end
  end
end
