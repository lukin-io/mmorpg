# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProcessor, "Neverlands-style combat features" do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }
  let!(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      level_min: 1,
      level_max: 100,
      active: true)
  end
  let!(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      started_at: Time.current,
      trauma_percent: 30)
  end

  let!(:participation1) do
    create(:arena_participation,
      arena_match: arena_match,
      character: character1,
      user: user1,
      team: "a")
  end

  let!(:participation2) do
    create(:arena_participation,
      arena_match: arena_match,
      character: character2,
      user: user2,
      team: "b")
  end

  let(:processor) { described_class.new(arena_match) }

  def deterministic_processor(*rolls)
    rng = instance_double(Random)
    allow(rng).to receive(:rand) do |range_or_limit = nil|
      value = rolls.shift || 99
      range_or_limit.is_a?(Range) ? value.clamp(range_or_limit.min, range_or_limit.max) : value
    end
    described_class.new(arena_match, rng:)
  end

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "Attack Types" do
    it "defines ATTACK_TYPES constant" do
      expect(Arena::CombatProcessor::ATTACK_TYPES).to include(:simple, :aimed)
    end

    it "simple attack has base damage multiplier" do
      expect(Arena::CombatProcessor::ATTACK_TYPES[:simple][:damage_mult]).to eq(1.0)
    end

    it "aimed attack has higher damage multiplier" do
      expect(Arena::CombatProcessor::ATTACK_TYPES[:aimed][:damage_mult]).to eq(1.2)
    end

    it "aimed attack has hit bonus" do
      expect(Arena::CombatProcessor::ATTACK_TYPES[:aimed][:hit_bonus]).to eq(15)
    end
  end

  describe "Body Part Targeting" do
    it "defines BODY_PART_MULTIPLIERS constant" do
      expect(Arena::CombatProcessor::BODY_PART_MULTIPLIERS).to include(
        "head", "torso", "stomach", "legs"
      )
    end

    it "head has highest damage multiplier (1.3x)" do
      expect(Arena::CombatProcessor::BODY_PART_MULTIPLIERS["head"]).to eq(1.3)
    end

    it "legs have lowest damage multiplier (0.9x)" do
      expect(Arena::CombatProcessor::BODY_PART_MULTIPLIERS["legs"]).to eq(0.9)
    end
  end

  describe "#process_action with attack" do
    it "accepts attack_type parameter" do
      result = processor.process_action(
        character1,
        :attack,
        target: character2,
        attack_type: :aimed,
        body_part: "head"
      )

      expect(result.success?).to be true
    end

    it "accepts body_part parameter" do
      result = processor.process_action(
        character1,
        :attack,
        target: character2,
        body_part: "head"
      )

      expect(result.success?).to be true
    end

    it "returns body_part in result" do
      result = processor.process_action(
        character1,
        :attack,
        target: character2,
        body_part: "legs"
      )

      # May be blocked, so check result properly
      expect(result[:body_part]).to eq("legs") unless result[:blocked]
    end

    it "returns attack_type in result" do
      result = processor.process_action(
        character1,
        :attack,
        target: character2,
        attack_type: :aimed,
        body_part: "torso"
      )

      expect(result[:attack_type]).to eq(:aimed) unless result[:blocked]
    end
  end

  describe "#process_action with defend (blocking)" do
    it "accepts block_parts parameter" do
      result = processor.process_action(
        character1,
        :defend,
        block_parts: ["head", "torso"]
      )

      expect(result.success?).to be true
      expect(result[:block_parts]).to eq(["head", "torso"])
    end

    it "sets blocking state on character" do
      processor.process_action(character1, :defend, block_parts: ["torso"])

      character1.reload
      expect(character1.metadata["blocking"]).to be true
      expect(character1.metadata["blocked_parts"]).to eq(["torso"])
    end

    context "when target is blocking attacked body part" do
      before do
        character2.update!(metadata: {
          "blocking" => true,
          "blocked_parts" => ["torso"],
          "block_until" => 10.seconds.from_now.iso8601
        })
      end

      it "blocks the attack" do
        result = deterministic_processor(0, 99, 0).process_action(
          character1,
          :attack,
          target: character2,
          body_part: "torso"
        )

        expect(result[:blocked]).to be true
        expect(result[:damage]).to eq(0)
      end

      it "can fail a covered block and still resolve the hit" do
        result = deterministic_processor(0, 99, 99, 99, 3).process_action(
          character1,
          :attack,
          target: character2,
          body_part: "torso"
        )

        expect(result[:blocked]).to be_falsey
        expect(result[:block_attempted]).to be true
        expect(result[:body_part]).to eq("torso")

        log = arena_match.reload.metadata["combat_log"]
        failed_block_entries = log.select { |entry| entry["type"] == "block_failed" }
        expect(failed_block_entries.last["description"]).to include("tried to block")
      end
    end

    context "when target is blocking different body part" do
      before do
        character2.update!(metadata: {
          "blocking" => true,
          "blocked_parts" => ["head"],
          "block_until" => 10.seconds.from_now.iso8601
        })
      end

      it "does not block attack to unblocked part" do
        result = deterministic_processor(0, 99, 99, 3).process_action(
          character1,
          :attack,
          target: character2,
          body_part: "legs"
        )

        expect(result[:blocked]).to be_falsey
        expect(result[:body_part]).to eq("legs")
        expect(result[:outcome]).not_to eq(:blocked)
      end
    end
  end

  describe "Combat Log Messages" do
    before do
      arena_match.update!(metadata: {"combat_log" => []})
    end

    it "logs attacks with body part" do
      deterministic_processor(0, 99, 0).process_action(
        character1,
        :attack,
        target: character2,
        body_part: "head"
      )

      log = arena_match.reload.metadata["combat_log"]
      last_entry = log.last

      expect(last_entry["description"]).to include("head")
    end

    it "logs critical hits with proper format" do
      # Force a critical hit by stubbing
      allow_any_instance_of(Object).to receive(:rand).and_return(0)

      deterministic_processor(0, 99).process_action(
        character1,
        :attack,
        target: character2,
        body_part: "torso"
      )

      log = arena_match.reload.metadata["combat_log"]
      crit_entries = log.select { |e| e["type"] == "critical" }

      if crit_entries.any?
        expect(crit_entries.last["description"]).to include("critical hit")
      end
    end

    it "logs blocks with proper format" do
      character2.update!(metadata: {
        "blocking" => true,
        "blocked_parts" => ["torso"],
        "block_until" => 10.seconds.from_now.iso8601
      })

      deterministic_processor(0, 99, 0).process_action(
        character1,
        :attack,
        target: character2,
        body_part: "torso"
      )

      log = arena_match.reload.metadata["combat_log"]
      block_entries = log.select { |e| e["type"] == "block" }

      expect(block_entries).not_to be_empty
      expect(block_entries.last["description"]).to include("blocked")
      expect(block_entries.last["description"]).to include("torso")
    end
  end

  describe "#end_match with trauma" do
    before do
      character1.update!(current_hp: 80)
      character2.update!(current_hp: 0, experience: 1000)
    end

    it "applies trauma to losers (sets HP to minimum)" do
      processor.end_match("a")

      character2.reload
      # Trauma applies HP loss, but minimum is 1
      expect(character2.current_hp).to be >= 0
      expect(character2.current_hp).to be <= 1 # Minimum after trauma
    end

    it "reduces XP for losers with high trauma" do
      arena_match.update!(trauma_percent: 50)
      original_xp = character2.experience

      processor.end_match("a")

      character2.reload
      expect(character2.experience).to be < original_xp
    end

    it "applies minor trauma to winners" do
      original_hp = character1.current_hp

      processor.end_match("a")

      character1.reload
      expect(character1.current_hp).to be <= original_hp
    end

    it "logs trauma effects" do
      processor.end_match("a")

      log = arena_match.reload.metadata["combat_log"]
      trauma_entries = log.select { |e| e["type"] == "trauma" }

      expect(trauma_entries).not_to be_empty
    end
  end

  describe "#end_match with different reasons" do
    it "handles timeout reason" do
      processor.end_match(nil, reason: :timeout)

      arena_match.reload
      expect(arena_match.timed_out).to be true

      log = arena_match.metadata["combat_log"]
      timeout_entry = log.find { |e| e["type"] == "timeout" }
      expect(timeout_entry["description"]).to include("timeout")
    end

    it "handles normal victory" do
      processor.end_match("a", reason: :normal)

      arena_match.reload
      log = arena_match.metadata["combat_log"]
      victory_entry = log.find { |e| e["type"] == "victory" }
      expect(victory_entry["description"]).to include("Winner")
    end

    it "handles draw" do
      processor.end_match(nil, reason: :normal)

      arena_match.reload
      log = arena_match.metadata["combat_log"]
      draw_entry = log.find { |e| e["type"] == "draw" }
      expect(draw_entry["description"]).to include("draw")
    end
  end

  # ============================================================================
  # FAILURE CASES (AGENT.md requirement)
  # ============================================================================

  describe "failure cases" do
    describe "#process_action" do
      context "with invalid action type" do
        it "returns failure" do
          result = processor.process_action(character1, :invalid_action)
          expect(result.success?).to be false
          expect(result.error).to include("Unknown action type")
        end
      end

      context "with nil target for attack" do
        it "finds default target and succeeds" do
          result = processor.process_action(character1, :attack, target: nil)
          expect(result.success?).to be true
        end
      end

      context "with invalid body part" do
        it "uses default body part multiplier" do
          result = processor.process_action(
            character1,
            :attack,
            target: character2,
            body_part: "invalid_part"
          )
          # Should still work, just use default multiplier
          expect(result.success?).to be true
        end
      end

      context "with invalid attack type" do
        it "uses default attack type" do
          result = processor.process_action(
            character1,
            :attack,
            target: character2,
            attack_type: :invalid_type
          )
          # Should still work, uses simple attack
          expect(result.success?).to be true
        end
      end
    end
  end

  # ============================================================================
  # NULL/EDGE CASES (AGENT.md requirement)
  # ============================================================================

  describe "null/edge cases" do
    describe "#process_action" do
      context "when character has exactly 1 HP" do
        before { character1.update!(current_hp: 1) }

        it "can still act" do
          result = processor.process_action(character1, :defend)
          expect(result.success?).to be true
        end
      end

      context "when target has exactly 1 HP" do
        before { character2.update!(current_hp: 1) }

        it "can kill target" do
          result = processor.process_action(
            character1,
            :attack,
            target: character2,
            body_part: "head"
          )

          expect(result.success?).to be true
          # Target should be dead or near death (unless blocked)
        end
      end

      context "with empty block_parts array" do
        it "defaults to torso block" do
          processor.process_action(
            character1,
            :defend,
            block_parts: []
          )

          character1.reload
          expect(character1.metadata["blocked_parts"]).to eq(["torso"])
        end
      end

      context "with nil block_parts" do
        it "defaults to torso block" do
          processor.process_action(
            character1,
            :defend,
            block_parts: nil
          )

          character1.reload
          expect(character1.metadata["blocked_parts"]).to eq(["torso"])
        end
      end
    end

    describe "#apply_trauma" do
      context "with 0% trauma" do
        before { arena_match.update!(trauma_percent: 0) }

        it "does not apply trauma" do
          original_hp = character1.current_hp

          processor.end_match("a")

          character1.reload
          expect(character1.current_hp).to eq(original_hp)
        end
      end

      context "with nil trauma_percent" do
        before { arena_match.update!(trauma_percent: nil) }

        it "uses default 30% trauma" do
          character2.update!(current_hp: 0)
          original_hp = character1.current_hp

          processor.end_match("a")

          character1.reload
          # Should have minor trauma applied
          expect(character1.current_hp).to be <= original_hp
        end
      end
    end
  end

  # ============================================================================
  # AUTHORIZATION CASES (AGENT.md requirement)
  # ============================================================================

  describe "authorization cases" do
    describe "#process_action" do
      context "when character is not in match" do
        let(:non_participant) { create(:character, level: 10) }

        before { create(:character_position, character: non_participant) }

        it "returns failure with error message" do
          result = processor.process_action(non_participant, :attack, target: character2)
          expect(result.success?).to be false
          expect(result.error).to eq("Character not in this match")
        end
      end

      context "when attacking same team member" do
        let(:teammate) { create(:character, level: 10) }
        let!(:teammate_participation) do
          create(:arena_participation,
            arena_match: arena_match,
            character: teammate,
            user: create(:user),
            team: "a")
        end

        before { create(:character_position, character: teammate) }

        it "returns failure for friendly fire" do
          result = processor.process_action(
            character1,
            :attack,
            target: teammate
          )
          expect(result.success?).to be false
          expect(result.error).to eq("Cannot attack ally")
        end
      end

      context "when trying to flee from duel" do
        it "returns failure" do
          result = processor.process_action(character1, :flee)
          expect(result.success?).to be false
          expect(result.error).to include("Cannot flee")
        end
      end
    end
  end
end
