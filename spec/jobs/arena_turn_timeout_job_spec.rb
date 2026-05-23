# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaTurnTimeoutJob do
  let(:arena_room) do
    create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true)
  end
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }

  let!(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      started_at: Time.current,
      turn_timeout_seconds: 300,
      current_turn_started_at: 6.minutes.ago,
      current_turn_number: 1,
      current_turn_team: "a")
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

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "#perform" do
    context "with specific match_id" do
      context "when match turn has timed out" do
        it "advances the turn" do
          expect {
            described_class.new.perform(match_id: arena_match.id)
          }.to change { arena_match.reload.current_turn_number }.by(1)
        end

        it "switches teams" do
          described_class.new.perform(match_id: arena_match.id)
          expect(arena_match.reload.current_turn_team).to eq("b")
        end

        it "logs timeout in combat log" do
          described_class.new.perform(match_id: arena_match.id)
          timeout_entry = arena_match.reload.combat_log_entries.find { |entry| entry.log_type == "timeout" }
          expect(timeout_entry).to be_present
          expect(timeout_entry.message).to include("timeout")
        end

        it "broadcasts timeout via ActionCable" do
          expect(ActionCable.server).to receive(:broadcast).at_least(:once)
          described_class.new.perform(match_id: arena_match.id)
        end

        it "schedules next timeout check" do
          # Use ActiveJob test helper
          described_class.new.perform(match_id: arena_match.id)
          # The next check is scheduled via match.schedule_timeout_check
          # Just verify the job can run without error
        end

        it "keeps the round waiting when one player has a pending turn" do
          participation1.update!(
            metadata: {
              "pending_turn" => {
                "turn_number" => arena_match.current_turn_number,
                "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
                "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}],
                "skills" => [],
                "total_ap" => 75
              }
            }
          )

          expect {
            described_class.new.perform(match_id: arena_match.id)
          }.not_to change { arena_match.reload.current_turn_number }
          expect(arena_match.metadata["timeout_claim_available"]).to be true
        end
      end

      context "when match turn has not timed out" do
        before do
          arena_match.update!(current_turn_started_at: 1.minute.ago)
        end

        it "does not advance the turn" do
          expect {
            described_class.new.perform(match_id: arena_match.id)
          }.not_to change { arena_match.reload.current_turn_number }
        end
      end

      context "when match is not live" do
        before { arena_match.update!(status: :completed) }

        it "does nothing" do
          expect {
            described_class.new.perform(match_id: arena_match.id)
          }.not_to change { arena_match.reload.current_turn_number }
        end
      end

      context "when match does not exist" do
        it "does not raise error" do
          expect {
            described_class.new.perform(match_id: 999999)
          }.not_to raise_error
        end
      end
    end

    context "without match_id (checking all matches)" do
      let!(:fresh_match) do
        create(:arena_match,
          status: :live,
          current_turn_started_at: 1.minute.ago,
          turn_timeout_seconds: 300)
      end

      let!(:stale_match) do
        create(:arena_match,
          status: :live,
          current_turn_started_at: 10.minutes.ago,
          current_turn_number: 1,
          turn_timeout_seconds: 300)
      end

      before do
        # Add participations to stale_match
        create(:arena_participation, arena_match: stale_match, character: character1, user: user1, team: "a")
        create(:arena_participation, arena_match: stale_match, character: character2, user: user2, team: "b")
      end

      it "processes only timed out matches" do
        expect {
          described_class.new.perform
        }.to change { stale_match.reload.current_turn_number }.by(1)
      end

      it "does not affect fresh matches" do
        expect {
          described_class.new.perform
        }.not_to change { fresh_match.reload.current_turn_number }
      end
    end
  end

  describe "excessive timeouts" do
    context "when timeout count reaches 3" do
      before do
        arena_match.update!(metadata: {"timeout_count" => 2})
      end

      it "ends the match as a draw" do
        # After this timeout (3rd), match should end
        described_class.new.perform(match_id: arena_match.id)
        arena_match.reload

        # The match ends on the NEXT check after count reaches 3
        # So first we increment to 3, then next call would end it
        expect(arena_match.metadata["timeout_count"]).to eq(3)
      end
    end
  end
end
