# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::ActionValidator do
  let(:config) do
    {
      "defaults" => {
        "action_points_per_turn" => 80,
        "max_mana_per_attack" => 50
      },
      "attack_types" => {
        "simple" => {"name" => "Simple", "action_cost" => 45},
        "aimed" => {"name" => "Aimed", "action_cost" => 60}
      },
      "block_types" => {
        "head_block" => {"name" => "Head Block", "action_cost" => 30},
        "torso_block" => {"name" => "Torso Block", "action_cost" => 30}
      },
      "magic_types" => {
        "fireball" => {"name" => "Fireball", "action_cost" => 40, "mana_cost" => 25}
      },
      "attack_penalties" => [
        {"attacks" => 0, "penalty" => 0},
        {"attacks" => 1, "penalty" => 0},
        {"attacks" => 2, "penalty" => 25},
        {"attacks" => 3, "penalty" => 75}
      ]
    }
  end

  let(:battle) { create(:battle, action_points_per_turn: 80) }
  let(:participant) do
    create(:battle_participant,
      battle: battle,
      is_alive: true,
      current_hp: 100,
      current_mp: 50)
  end

  let(:validator) { described_class.new(participant, config) }

  describe "#validate" do
    context "with success cases" do
      it "validates single attack" do
        attacks = [{body_part: "head", action_key: "simple"}]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be true
        expect(result.errors).to be_empty
        expect(result.total_ap).to eq(45)
      end

      it "validates attack with block" do
        attacks = [{body_part: "head", action_key: "simple"}]
        blocks = [{body_part: "torso", action_key: "torso_block"}]

        result = validator.validate(attacks: attacks, blocks: blocks)

        expect(result.valid?).to be true
        expect(result.total_ap).to eq(75) # 45 + 30
      end

      it "validates multiple attacks within limit" do
        attacks = [
          {body_part: "head", action_key: "simple"},
          {body_part: "torso", action_key: "simple"}
        ]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be true
        expect(result.total_ap).to eq(115) # 45 + 45 + 25 penalty
      end

      it "includes warnings for high mana usage" do
        skills = [{key: "fireball", mana: 25}, {key: "fireball", mana: 30}]

        result = validator.validate(skills: skills)

        expect(result.warnings).to include(a_string_matching(/mana usage/i))
      end
    end

    context "with failure cases - attack exclusivity" do
      it "rejects head+legs attacks in same turn" do
        attacks = [
          {body_part: "head", action_key: "simple"},
          {body_part: "legs", action_key: "simple"}
        ]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/head.*legs/i))
      end

      it "rejects legs+head attacks in same turn" do
        attacks = [
          {body_part: "legs", action_key: "simple"},
          {body_part: "head", action_key: "simple"}
        ]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
      end
    end

    context "with failure cases - block limit" do
      it "rejects more than one block per turn" do
        blocks = [
          {body_part: "head", action_key: "head_block"},
          {body_part: "torso", action_key: "torso_block"}
        ]

        result = validator.validate(blocks: blocks)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/block.*allowed/i))
      end
    end

    context "with failure cases - attack limit" do
      it "rejects more than 4 attacks per turn" do
        attacks = [
          {body_part: "head", action_key: "simple"},
          {body_part: "torso", action_key: "simple"},
          {body_part: "stomach", action_key: "simple"},
          {body_part: "legs", action_key: "simple"},
          {body_part: "head", action_key: "aimed"}
        ]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/maximum.*4.*attacks/i))
      end
    end

    context "with failure cases - AP limit" do
      it "rejects actions exceeding AP limit" do
        attacks = [
          {body_part: "head", action_key: "aimed"},
          {body_part: "torso", action_key: "aimed"}
        ]
        # 60 + 60 + 25 penalty = 145 > 80

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/exceed.*AP/i))
      end
    end

    context "with failure cases - mana" do
      it "rejects skills when not enough MP" do
        participant.update!(current_mp: 10)
        skills = [{key: "fireball", mana: 25}]

        result = validator.validate(skills: skills)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/not enough MP/i))
      end
    end

    context "with failure cases - participant state" do
      it "rejects actions when participant is dead" do
        participant.update!(is_alive: false)
        attacks = [{body_part: "head", action_key: "simple"}]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
        expect(result.errors).to include(a_string_matching(/defeated/i))
      end

      it "rejects actions when participant has no HP" do
        participant.update!(current_hp: 0)
        attacks = [{body_part: "head", action_key: "simple"}]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be false
      end
    end

    context "with edge cases" do
      it "handles empty attacks array" do
        result = validator.validate(attacks: [])

        expect(result.valid?).to be true
        expect(result.total_ap).to eq(0)
      end

      it "handles nil participant" do
        validator = described_class.new(nil, config)

        result = validator.validate(attacks: [{body_part: "head", action_key: "simple"}])

        # Should still calculate AP even without participant
        expect(result.total_ap).to be > 0
      end

      it "handles string keys in attacks hash" do
        attacks = [{"body_part" => "head", "action_key" => "simple"}]

        result = validator.validate(attacks: attacks)

        expect(result.valid?).to be true
      end
    end
  end

  describe "#validate_attack_selection" do
    context "with exclusivity rules" do
      it "returns valid for non-conflicting attacks" do
        existing = [{body_part: "torso", action_key: "simple"}]

        result = validator.validate_attack_selection(
          body_part: "stomach",
          action_key: "simple",
          existing_attacks: existing
        )

        expect(result[:valid]).to be true
      end

      it "returns invalid for head when legs selected" do
        existing = [{body_part: "legs", action_key: "simple"}]

        result = validator.validate_attack_selection(
          body_part: "head",
          action_key: "simple",
          existing_attacks: existing
        )

        expect(result[:valid]).to be false
        expect(result[:error]).to include("head")
      end

      it "returns invalid when at max attacks" do
        existing = (1..4).map { |i| {body_part: "torso", action_key: "simple"} }

        result = validator.validate_attack_selection(
          body_part: "head",
          action_key: "simple",
          existing_attacks: existing
        )

        expect(result[:valid]).to be false
        expect(result[:error]).to include("Maximum")
      end
    end
  end

  describe "#validate_block_selection" do
    context "with block rules" do
      it "returns valid for first block" do
        result = validator.validate_block_selection(
          body_part: "head",
          existing_blocks: []
        )

        expect(result[:valid]).to be true
      end

      it "returns invalid when block already selected" do
        existing = [{body_part: "torso", action_key: "torso_block"}]

        result = validator.validate_block_selection(
          body_part: "head",
          existing_blocks: existing
        )

        expect(result[:valid]).to be false
        expect(result[:error]).to include("block")
      end
    end
  end
end
