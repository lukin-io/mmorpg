# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatch, "Auto-End Functionality" do
  include ActiveSupport::Testing::TimeHelpers

  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true, max_concurrent_matches: 5) }
  let(:character1) { create(:character, name: "Fighter1", level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, name: "Fighter2", level: 10, current_hp: 100, max_hp: 100) }

  let!(:match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      turn_timeout_seconds: 300, # 5 minutes
      started_at: Time.current)
  end

  let!(:participation1) { create(:arena_participation, arena_match: match, character: character1, user: character1.user, team: "a") }
  let!(:participation2) { create(:arena_participation, arena_match: match, character: character2, user: character2.user, team: "b") }

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "#stale?" do
    context "when match is not live" do
      before { match.update!(status: :completed) }

      it "returns false" do
        expect(match.stale?).to be false
      end
    end

    context "when match has no started_at" do
      before { match.update!(started_at: nil) }

      it "returns false" do
        expect(match.stale?).to be false
      end
    end

    context "when match is within allowed duration" do
      it "returns false for fresh match" do
        expect(match.stale?).to be false
      end

      it "returns false when just under 2x timeout" do
        travel_to(match.started_at + 9.minutes) do
          expect(match.stale?).to be false
        end
      end
    end

    context "when match exceeds 2x turn timeout" do
      it "returns true when past 2x timeout" do
        travel_to(match.started_at + 11.minutes) do
          expect(match.stale?).to be true
        end
      end

      it "returns true for day-old match" do
        travel_to(match.started_at + 1.day) do
          expect(match.stale?).to be true
        end
      end
    end
  end

  describe "#should_auto_end_defeat?" do
    context "when match is not live" do
      before { match.update!(status: :pending) }

      it "returns false" do
        expect(match.should_auto_end_defeat?).to be false
      end
    end

    context "when both players have HP" do
      it "returns false" do
        expect(match.should_auto_end_defeat?).to be false
      end
    end

    context "when one player is defeated" do
      before { character1.update!(current_hp: 0) }

      it "returns true" do
        expect(match.should_auto_end_defeat?).to be true
      end
    end

    context "when both players are defeated (edge case)" do
      before do
        character1.update!(current_hp: 0)
        character2.update!(current_hp: 0)
      end

      it "returns true" do
        expect(match.should_auto_end_defeat?).to be true
      end
    end
  end

  describe "#participant_defeated?" do
    context "with player character" do
      let(:participation) { participation1 }

      it "returns false when character has HP" do
        expect(match.participant_defeated?(participation)).to be false
      end

      it "returns true when character HP is 0" do
        character1.update!(current_hp: 0)
        expect(match.participant_defeated?(participation)).to be true
      end

      it "returns true when character HP is negative" do
        character1.update!(current_hp: -5)
        expect(match.participant_defeated?(participation)).to be true
      end
    end

    context "with NPC participant" do
      let(:npc_template) { create(:npc_template, name: "Test NPC", level: 5) }
      let(:npc_participation) do
        create(:arena_participation,
          arena_match: match,
          npc_template: npc_template,
          character: nil,
          team: "b",
          metadata: {"current_hp" => 50, "max_hp" => 50})
      end

      it "returns false when NPC has HP" do
        expect(match.participant_defeated?(npc_participation)).to be false
      end

      it "returns true when NPC HP is 0" do
        npc_participation.update!(metadata: npc_participation.metadata.merge("current_hp" => 0))
        expect(match.participant_defeated?(npc_participation)).to be true
      end
    end
  end

  describe "#determine_winner" do
    context "when team a has surviving members" do
      before { character2.update!(current_hp: 0) }

      it "returns team a" do
        expect(match.determine_winner).to eq("a")
      end
    end

    context "when team b has surviving members" do
      before { character1.update!(current_hp: 0) }

      it "returns team b" do
        expect(match.determine_winner).to eq("b")
      end
    end

    context "when both teams have survivors (draw)" do
      it "returns nil" do
        expect(match.determine_winner).to be_nil
      end
    end

    context "when both teams are eliminated (draw)" do
      before do
        character1.update!(current_hp: 0)
        character2.update!(current_hp: 0)
      end

      it "returns nil" do
        expect(match.determine_winner).to be_nil
      end
    end
  end

  describe "#auto_end_if_needed!" do
    context "when match is not live" do
      before { match.update!(status: :completed) }

      it "returns false" do
        expect(match.auto_end_if_needed!).to be false
      end

      it "does not change status" do
        expect { match.auto_end_if_needed! }.not_to change { match.reload.status }
      end
    end

    context "when match should end due to defeat" do
      before { character2.update!(current_hp: 0) }

      it "returns true" do
        expect(match.auto_end_if_needed!).to be true
      end

      it "sets match to completed" do
        match.auto_end_if_needed!
        expect(match.reload.status).to eq("completed")
      end

      it "sets winning team" do
        match.auto_end_if_needed!
        expect(match.reload.winning_team).to eq("a")
      end

      it "sets ended_at" do
        match.auto_end_if_needed!
        expect(match.reload.ended_at).to be_present
      end
    end

    context "when match is stale (timeout)" do
      it "returns true and ends match" do
        travel_to(match.started_at + 15.minutes) do
          expect(match.auto_end_if_needed!).to be true
          expect(match.reload.status).to eq("completed")
          expect(match.reload.timed_out).to be true
        end
      end

      it "sets winning team when someone is defeated" do
        character2.update!(current_hp: 0) # Defeated

        travel_to(match.started_at + 15.minutes) do
          match.auto_end_if_needed!
          expect(match.reload.winning_team).to eq("a")
        end
      end
    end

    context "when match is ongoing normally" do
      it "returns false" do
        expect(match.auto_end_if_needed!).to be false
      end

      it "does not change status" do
        expect { match.auto_end_if_needed! }.not_to change { match.reload.status }
      end
    end
  end
end
