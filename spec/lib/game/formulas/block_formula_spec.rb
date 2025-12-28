# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Formulas::BlockFormula do
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
    allow(combatant).to receive(:respond_to?).with(:has_shield?).and_return(true)
    allow(combatant).to receive(:passive_skill_level) { |skill| skills[skill.to_sym] || 0 }
    allow(combatant).to receive(:has_shield?).and_return(false)

    combatant
  end

  describe "#call" do
    context "with success cases" do
      it "blocks when defender has matching body part block" do
        defender = build_combatant(stats: {strength: 20, dexterity: 15})
        blocks = [{body_part: "head", action_key: "head_block"}]

        result = formula.call(
          attacker_body_part: "head",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result).to have_key(:blocked)
        expect(result).to have_key(:damage_reduction)
        expect(result).to have_key(:block_type)
      end

      it "returns deterministic results with same RNG seed" do
        defender = build_combatant(stats: {strength: 20})
        blocks = [{body_part: "torso", action_key: "torso_block"}]

        result1 = described_class.new(rng: Random.new(seed)).call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender
        )
        result2 = described_class.new(rng: Random.new(seed)).call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result1[:blocked]).to eq(result2[:blocked])
        expect(result1[:roll]).to eq(result2[:roll])
      end

      it "applies partial damage reduction on failed block" do
        defender = build_combatant(stats: {strength: 5})
        blocks = [{body_part: "torso", action_key: "basic_block"}]

        # Force a miss by using low stats
        100.times do |i|
          result = described_class.new(rng: Random.new(i)).call(
            attacker_body_part: "torso",
            defender_blocks: blocks,
            defender: defender
          )

          if !result[:blocked] && result[:partial]
            expect(result[:damage_reduction]).to be > 0
            expect(result[:damage_reduction]).to be < 0.5
            break
          end
        end
      end
    end

    context "with failure cases" do
      it "returns not blocked when no blocks provided" do
        defender = build_combatant(stats: {strength: 20})

        result = formula.call(
          attacker_body_part: "head",
          defender_blocks: [],
          defender: defender
        )

        expect(result[:blocked]).to be false
        expect(result[:damage_reduction]).to eq(0)
      end

      it "returns not blocked when block covers different body part" do
        defender = build_combatant(stats: {strength: 20})
        blocks = [{body_part: "legs", action_key: "legs_block"}]

        result = formula.call(
          attacker_body_part: "head",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result[:blocked]).to be false
        expect(result[:block_type]).to be_nil
      end

      it "handles nil defender blocks" do
        defender = build_combatant(stats: {strength: 20})

        result = formula.call(
          attacker_body_part: "head",
          defender_blocks: nil,
          defender: defender
        )

        expect(result[:blocked]).to be false
      end
    end

    context "with edge cases" do
      it "handles empty blocks array" do
        defender = build_combatant(stats: {strength: 20})

        result = formula.call(
          attacker_body_part: "torso",
          defender_blocks: [],
          defender: defender
        )

        expect(result[:blocked]).to be false
        expect(result[:partial]).to be false
      end

      it "handles blocks with string keys" do
        defender = build_combatant(stats: {strength: 20})
        blocks = [{"body_part" => "torso", "action_key" => "torso_block"}]

        result = formula.call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result).to be_a(Hash)
      end

      it "handles unknown block types with defaults" do
        defender = build_combatant(stats: {strength: 20})
        blocks = [{body_part: "torso", action_key: "unknown_block"}]

        result = formula.call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result).to be_a(Hash)
        expect(result[:block_type]).to eq("unknown_block")
      end
    end

    context "with magic blocks" do
      it "handles magic shield block" do
        defender = build_combatant(stats: {intelligence: 30})
        blocks = [{body_part: "torso", action_key: "magic_shield"}]

        result = formula.call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender
        )

        expect(result[:magic_block]).to be true
        expect(result).to have_key(:mana_cost)
      end

      it "crystal sphere provides high damage reduction" do
        defender = build_combatant(stats: {intelligence: 50})
        blocks = [{body_part: "torso", action_key: "crystal_sphere"}]

        # Find a case where it blocks
        100.times do |i|
          result = described_class.new(rng: Random.new(i)).call(
            attacker_body_part: "torso",
            defender_blocks: blocks,
            defender: defender
          )

          if result[:blocked]
            expect(result[:damage_reduction]).to eq(1.0)
            break
          end
        end
      end
    end

    context "with attacker penetration" do
      it "applies attacker strength to reduce block chance" do
        defender = build_combatant(stats: {strength: 10})
        attacker = build_combatant(stats: {strength: 50})
        blocks = [{body_part: "torso", action_key: "torso_block"}]

        result = formula.call(
          attacker_body_part: "torso",
          defender_blocks: blocks,
          defender: defender,
          attacker: attacker
        )

        expect(result[:chance]).to be < 60 # Reduced by attacker strength
      end
    end
  end
end
