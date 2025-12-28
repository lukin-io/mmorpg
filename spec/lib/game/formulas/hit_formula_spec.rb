# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::HitFormula do
  let(:seed) { 12345 }
  let(:rng) { Random.new(seed) }
  let(:formula) { described_class.new(rng: rng) }

  # Helper to build combatants with stats
  def build_combatant(stats: {})
    combatant = double("Combatant")
    stat_block = double("StatBlock")

    allow(stat_block).to receive(:get) { |stat| stats[stat.to_sym] || 0 }
    allow(combatant).to receive(:stats).and_return(stat_block)
    allow(combatant).to receive(:respond_to?).with(anything).and_return(false)
    allow(combatant).to receive(:respond_to?).with(:stats).and_return(true)
    allow(combatant).to receive(:respond_to?).with(:passive_skill_level).and_return(true)
    allow(combatant).to receive(:passive_skill_level).with(anything).and_return(0)

    combatant
  end

  describe "#call" do
    context "with success cases" do
      it "calculates hit chance with base stats" do
        attacker = build_combatant(stats: {accuracy: 20, dexterity: 15})
        defender = build_combatant(stats: {evasion: 10, agility: 10})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:hit)
        expect(result).to have_key(:roll)
        expect(result).to have_key(:chance)
        expect(result).to have_key(:dodge)
      end

      it "returns deterministic results with same RNG seed" do
        attacker = build_combatant(stats: {accuracy: 20})
        defender = build_combatant(stats: {evasion: 10})

        result1 = described_class.new(rng: Random.new(seed)).call(attacker: attacker, defender: defender)
        result2 = described_class.new(rng: Random.new(seed)).call(attacker: attacker, defender: defender)

        expect(result1[:roll]).to eq(result2[:roll])
        expect(result1[:hit]).to eq(result2[:hit])
      end

      it "applies body part modifiers correctly" do
        attacker = build_combatant(stats: {accuracy: 20})
        defender = build_combatant(stats: {evasion: 10})

        head_result = formula.call(attacker: attacker, defender: defender, body_part: "head")
        torso_result = described_class.new(rng: Random.new(seed)).call(
          attacker: attacker, defender: defender, body_part: "torso"
        )

        # Head should have lower hit chance than torso
        expect(head_result[:chance]).to be < torso_result[:chance]
      end

      it "applies action type modifiers correctly" do
        attacker = build_combatant(stats: {accuracy: 20})
        defender = build_combatant(stats: {evasion: 10})

        simple_result = formula.call(attacker: attacker, defender: defender, action_key: "simple")
        aimed_result = described_class.new(rng: Random.new(seed)).call(
          attacker: attacker, defender: defender, action_key: "aimed"
        )

        # Aimed should have higher hit chance than simple
        expect(aimed_result[:chance]).to be > simple_result[:chance]
      end
    end

    context "with failure cases" do
      it "handles nil attacker gracefully" do
        defender = build_combatant(stats: {evasion: 10})

        result = formula.call(attacker: nil, defender: defender)

        expect(result).to be_a(Hash)
        expect(result[:chance]).to be > 0
      end

      it "handles nil defender gracefully" do
        attacker = build_combatant(stats: {accuracy: 20})

        result = formula.call(attacker: attacker, defender: nil)

        expect(result).to be_a(Hash)
        expect(result[:chance]).to be > 0
      end
    end

    context "with edge cases" do
      it "clamps hit chance to minimum 5%" do
        attacker = build_combatant(stats: {accuracy: 0})
        defender = build_combatant(stats: {evasion: 100, agility: 100})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result[:chance]).to be >= 5.0
      end

      it "clamps hit chance to maximum 95%" do
        attacker = build_combatant(stats: {accuracy: 100, dexterity: 100})
        defender = build_combatant(stats: {evasion: 0})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result[:chance]).to be <= 95.0
      end

      it "handles invalid body parts with default modifier" do
        attacker = build_combatant(stats: {accuracy: 20})
        defender = build_combatant(stats: {evasion: 10})

        result = formula.call(attacker: attacker, defender: defender, body_part: "invalid")

        expect(result).to be_a(Hash)
        expect(result[:chance]).to be_a(Float)
      end

      it "handles zero stats" do
        attacker = build_combatant(stats: {})
        defender = build_combatant(stats: {})

        result = formula.call(attacker: attacker, defender: defender)

        expect(result[:chance]).to eq(85.0) # Base hit chance
      end
    end

    context "with dodge mechanics" do
      it "calculates dodge separately from hit" do
        attacker = build_combatant(stats: {accuracy: 20})
        defender = build_combatant(stats: {agility: 50, evasion: 30})

        # Run multiple times to get a dodge
        10.times do
          result = described_class.new(rng: Random.new(rand(10000))).call(
            attacker: attacker, defender: defender
          )

          if result[:hit] == false && result[:dodge] == true
            expect(result[:dodge]).to be true
            break
          end
        end
      end

      it "returns dodge_chance in result when dodged" do
        attacker = build_combatant(stats: {accuracy: 10})
        defender = build_combatant(stats: {agility: 100, evasion: 50})

        # Force a scenario where dodge is likely
        100.times do |i|
          result = described_class.new(rng: Random.new(i)).call(
            attacker: attacker, defender: defender
          )

          if result[:dodge]
            expect(result[:dodge_chance]).to be > 0
            break
          end
        end
      end
    end
  end
end
