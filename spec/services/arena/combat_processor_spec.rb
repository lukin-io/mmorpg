# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProcessor do
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
      started_at: Time.current)
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

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "#process_action" do
    context "with attack action" do
      it "deals damage to target" do
        initial_hp = character2.current_hp

        result = processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        # Could be blocked, so check for success or blocked
        expect(result.success?).to be true
        if result[:blocked]
          expect(character2.reload.current_hp).to eq(initial_hp)
        else
          expect(character2.reload.current_hp).to be < initial_hp
        end
      end

      it "returns damage data" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        if result[:blocked]
          expect(result[:damage]).to eq(0)
        else
          expect(result[:damage]).to be_a(Integer)
          expect(result[:damage]).to be > 0
        end
      end

      it "broadcasts combat action" do
        # Allow for either attack or blocked broadcast
        allow(processor.broadcaster).to receive(:broadcast_combat_action)

        processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        expect(processor.broadcaster).to have_received(:broadcast_combat_action)
          .with(character1, anything, anything, kind_of(Integer), hash_including(:body_part))
      end
    end

    context "with defend action" do
      it "sets defending state with block parts" do
        result = processor.process_action(
          character1,
          :defend,
          block_parts: ["torso"]
        )

        expect(result.success?).to be true
        expect(result[:defending]).to be true
        expect(result[:block_parts]).to eq(["torso"])
      end
    end

    context "when match is not live" do
      before do
        arena_match.update!(status: :completed)
      end

      it "returns failure" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Match is not active")
      end
    end

    context "when character is not in match" do
      let(:non_participant) { create(:character, level: 10) }

      before do
        create(:character_position, character: non_participant)
      end

      it "returns failure" do
        result = processor.process_action(
          non_participant,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Character not in this match")
      end
    end

    context "when character is dead" do
      before do
        character1.update!(current_hp: 0)
      end

      it "returns failure" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Character is dead")
      end
    end
  end

  describe "#should_end?" do
    it "returns false when both teams have living members" do
      expect(processor.should_end?).to be false
    end

    it "returns true when one team is eliminated" do
      character2.update!(current_hp: 0)

      expect(processor.should_end?).to be true
    end
  end

  describe "#determine_winner" do
    it "returns team with living members" do
      character2.update!(current_hp: 0)

      expect(processor.determine_winner).to eq("a")
    end

    it "returns team with higher HP when both alive" do
      character1.update!(current_hp: 80)
      character2.update!(current_hp: 50)

      expect(processor.determine_winner).to eq("a")
    end

    it "returns nil for draw" do
      character1.update!(current_hp: 50)
      character2.update!(current_hp: 50)

      expect(processor.determine_winner).to be_nil
    end
  end

  describe "#end_match" do
    it "updates match status to completed" do
      processor.end_match("a")

      expect(arena_match.reload.status).to eq("completed")
      expect(arena_match.ended_at).to be_present
      expect(arena_match.winning_team).to eq("a")
    end

    it "finalizes participations" do
      processor.end_match("a")

      expect(participation1.reload.result).to eq("victory")
      expect(participation2.reload.result).to eq("defeat")
    end

    it "broadcasts match ended" do
      expect(processor.broadcaster).to receive(:broadcast_match_ended).with("a", reason: :normal)

      processor.end_match("a")
    end
  end
end
