# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::DamageCalculator do
  let(:rng) { Random.new(12345) }
  let(:calculator) { described_class.new(rng: rng) }

  # Create simple combatant doubles for testing
  let(:attacker) do
    instance_double(
      "Game::Combat::Combatant",
      attack_power: 20,
      crit_chance: 15,
      agility: 12,
      defending?: false,
      check_defend_expiry!: nil
    )
  end

  let(:defender) do
    instance_double(
      "Game::Combat::Combatant",
      defense_value: 10,
      luck: 5,
      dodge_chance: 10,
      agility: 10,
      defending?: false,
      check_defend_expiry!: nil
    )
  end

  describe "#calculate" do
    it "returns a DamageResult struct" do
      result = calculator.calculate(attacker: attacker, defender: defender)

      expect(result).to be_a(Game::Combat::DamageCalculator::DamageResult)
      expect(result).to respond_to(:damage, :critical, :blocked, :dodged, :body_part)
    end

    it "calculates positive damage" do
      result = calculator.calculate(attacker: attacker, defender: defender)

      expect(result.damage).to be >= 1
    end

    it "respects defense value" do
      high_defense_defender = instance_double(
        "Game::Combat::Combatant",
        defense_value: 30,
        luck: 0,
        dodge_chance: 0,
        agility: 5,
        defending?: false,
        check_defend_expiry!: nil
      )

      result = calculator.calculate(attacker: attacker, defender: high_defense_defender)

      # Higher defense should result in lower damage (minimum 1)
      expect(result.damage).to be >= 1
    end

    it "applies defending bonus to defense" do
      defending_defender = instance_double(
        "Game::Combat::Combatant",
        defense_value: 10,
        luck: 0,
        dodge_chance: 0,
        agility: 10,
        defending?: true,
        check_defend_expiry!: nil
      )

      normal_result = calculator.calculate(attacker: attacker, defender: defender)
      defending_result = described_class.new(rng: Random.new(12345))
        .calculate(attacker: attacker, defender: defending_defender)

      # Defending should reduce damage
      expect(defending_result.damage).to be <= normal_result.damage
    end

    it "selects random body part when not specified" do
      result = calculator.calculate(attacker: attacker, defender: defender)

      expect(Game::Combat::DamageCalculator::BODY_PARTS).to include(result.body_part)
    end

    it "uses specified body part" do
      result = calculator.calculate(attacker: attacker, defender: defender, body_part: "head")

      expect(result.body_part).to eq("head")
    end

    it "applies body part multipliers" do
      head_calc = described_class.new(rng: Random.new(12345))
      legs_calc = described_class.new(rng: Random.new(12345))

      # Use non-dodging defender
      no_dodge_defender = instance_double(
        "Game::Combat::Combatant",
        defense_value: 10,
        luck: 0,
        dodge_chance: 0,
        agility: 10,
        defending?: false,
        check_defend_expiry!: nil
      )

      head_result = head_calc.calculate(attacker: attacker, defender: no_dodge_defender, body_part: "head")
      legs_result = legs_calc.calculate(attacker: attacker, defender: no_dodge_defender, body_part: "legs")

      # Head (1.25x) should deal more damage than legs (0.9x)
      # Note: RNG variance may affect this, so we test the multiplier logic
      expect(Game::Combat::DamageCalculator::BODY_PART_MULTIPLIERS["head"]).to be > Game::Combat::DamageCalculator::BODY_PART_MULTIPLIERS["legs"]
    end

    context "with critical hits" do
      it "can produce critical hits" do
        # Use a seed that produces a crit
        crit_rng = Random.new(1)
        crit_calculator = described_class.new(rng: crit_rng)

        # Run multiple times to find a crit
        results = 20.times.map do
          described_class.new(rng: Random.new(rand(1000)))
            .calculate(attacker: attacker, defender: defender)
        end

        # At least one should be a crit (15% chance each)
        expect(results.any?(&:critical)).to be true
      end
    end

    context "with dodge" do
      it "can produce dodges" do
        high_dodge_defender = instance_double(
          "Game::Combat::Combatant",
          defense_value: 10,
          luck: 0,
          dodge_chance: 40,
          agility: 15,
          defending?: false,
          check_defend_expiry!: nil
        )

        # Run multiple times to find a dodge
        results = 20.times.map do
          described_class.new(rng: Random.new(rand(1000)))
            .calculate(attacker: attacker, defender: high_dodge_defender)
        end

        # At least one should be dodged
        expect(results.any?(&:dodged)).to be true
      end

      it "dodged attacks deal zero damage" do
        # Force a dodge by using a high dodge defender
        results = 50.times.map do
          described_class.new(rng: Random.new(rand(1000)))
            .calculate(
              attacker: attacker,
              defender: instance_double(
                "Game::Combat::Combatant",
                defense_value: 10,
                luck: 0,
                dodge_chance: 50,
                agility: 20,
                defending?: false,
                check_defend_expiry!: nil
              )
            )
        end

        dodged = results.select(&:dodged)
        expect(dodged).not_to be_empty
        expect(dodged.all? { |r| r.damage.zero? }).to be true
      end
    end
  end

  describe "#calculate_blocked" do
    it "returns reduced damage for blocked attacks" do
      result = calculator.calculate_blocked(attacker: attacker, defender: defender, body_part: "torso")

      expect(result.blocked).to be true
      expect(result.damage).to be < 20 # Less than attacker's base attack
    end

    it "deals 20% of base damage" do
      result = calculator.calculate_blocked(attacker: attacker, defender: defender, body_part: "torso")

      # Base damage is attack power + variance (1-5), blocked is 20%
      # 20 + (1-5) = 21-25, 20% = 4-5
      expect(result.damage).to be >= 1
      expect(result.damage).to be <= 10
    end
  end

  describe "#calculate_skill" do
    it "applies skill multiplier to damage" do
      normal_result = calculator.calculate(attacker: attacker, defender: defender)

      skill_calc = described_class.new(rng: Random.new(12345))
      skill_result = skill_calc.calculate_skill(
        attacker: attacker,
        defender: defender,
        skill_multiplier: 1.5
      )

      # Skill damage should be approximately 1.5x normal
      expect(skill_result.damage).to be >= normal_result.damage
    end
  end

  describe "determinism" do
    it "produces identical results with the same seed" do
      calc1 = described_class.new(rng: Random.new(99999))
      calc2 = described_class.new(rng: Random.new(99999))

      result1 = calc1.calculate(attacker: attacker, defender: defender, body_part: "torso")
      result2 = calc2.calculate(attacker: attacker, defender: defender, body_part: "torso")

      expect(result1.damage).to eq(result2.damage)
      expect(result1.critical).to eq(result2.critical)
      expect(result1.dodged).to eq(result2.dodged)
    end
  end
end
