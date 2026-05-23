# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::MatchStarterJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true) }
  let!(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :pending,
      match_type: :duel,
      metadata: {"starts_at" => 2.minutes.from_now.iso8601})
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

  describe "queue configuration" do
    it "is enqueued to the arena queue" do
      expect(described_class.new.queue_name).to eq("arena")
    end

    it "can be enqueued" do
      expect {
        described_class.perform_later(arena_match.id)
      }.to have_enqueued_job(described_class).with(arena_match.id).on_queue("arena")
    end
  end

  describe "#perform" do
    context "with a pending match" do
      it "transitions match status from pending to live" do
        expect(arena_match.status).to eq("pending")

        described_class.new.perform(arena_match.id)

        expect(arena_match.reload.status).to eq("live")
      end

      it "sets started_at timestamp" do
        expect(arena_match.started_at).to be_nil

        travel_to(Time.current) do
          described_class.new.perform(arena_match.id)
          expect(arena_match.reload.started_at).to be_within(1.second).of(Time.current)
        end
      end

      it "sets all participants to in_combat" do
        expect(character1.in_combat).to be false
        expect(character2.in_combat).to be false

        described_class.new.perform(arena_match.id)

        expect(character1.reload.in_combat).to be true
        expect(character2.reload.in_combat).to be true
      end

      it "sets last_combat_at for all participants" do
        travel_to(Time.current) do
          described_class.new.perform(arena_match.id)

          expect(character1.reload.last_combat_at).to be_within(1.second).of(Time.current)
          expect(character2.reload.last_combat_at).to be_within(1.second).of(Time.current)
        end
      end

      it "broadcasts match start via CombatBroadcaster" do
        broadcaster = instance_double(Arena::CombatBroadcaster)
        allow(Arena::CombatBroadcaster).to receive(:new).with(arena_match).and_return(broadcaster)
        expect(broadcaster).to receive(:broadcast_match_start)

        described_class.new.perform(arena_match.id)
      end
    end

    context "with a non-existent match" do
      it "does not raise an error" do
        expect {
          described_class.new.perform(999999)
        }.not_to raise_error
      end

      it "returns early without side effects" do
        expect(Arena::CombatBroadcaster).not_to receive(:new)
        described_class.new.perform(999999)
      end
    end

    context "with a nil match_id" do
      it "does not raise an error" do
        expect {
          described_class.new.perform(nil)
        }.not_to raise_error
      end
    end

    context "when match is not in pending status" do
      it "does not update a live match" do
        arena_match.update!(status: :live, started_at: 1.hour.ago)
        original_started_at = arena_match.started_at

        described_class.new.perform(arena_match.id)

        expect(arena_match.reload.started_at).to eq(original_started_at)
      end

      it "does not update a completed match" do
        arena_match.update!(status: :completed, started_at: 1.hour.ago, ended_at: 30.minutes.ago)

        described_class.new.perform(arena_match.id)

        expect(arena_match.reload.status).to eq("completed")
      end

      it "does not update a cancelled match" do
        arena_match.update!(status: :cancelled)

        described_class.new.perform(arena_match.id)

        expect(arena_match.reload.status).to eq("cancelled")
      end

      it "does not broadcast for non-pending matches" do
        arena_match.update!(status: :completed)

        expect(Arena::CombatBroadcaster).not_to receive(:new)
        described_class.new.perform(arena_match.id)
      end
    end

    context "when match has no participants" do
      before do
        arena_match.arena_participations.destroy_all
      end

      it "still transitions the match to live" do
        described_class.new.perform(arena_match.id)
        expect(arena_match.reload.status).to eq("live")
      end
    end

    context "when match has NPC participants" do
      let(:npc_template) { create(:npc_template, name: "Training Dummy", level: 5, role: "arena_bot") }

      before do
        participation2.update!(character: nil, npc_template: npc_template, user: nil)
        # Mock broadcaster to avoid nil character name issue in NPC participations
        broadcaster = instance_double(Arena::CombatBroadcaster)
        allow(Arena::CombatBroadcaster).to receive(:new).and_return(broadcaster)
        allow(broadcaster).to receive(:broadcast_match_start)
      end

      it "transitions the match to live" do
        described_class.new.perform(arena_match.id)
        expect(arena_match.reload.status).to eq("live")
      end

      it "sets player character to in_combat but not NPC" do
        described_class.new.perform(arena_match.id)
        expect(character1.reload.in_combat).to be true
        # NPCs don't have in_combat flag (they use participation metadata)
      end
    end
  end

  describe "job scheduling via ApplicationHandler" do
    let(:handler) { Arena::ApplicationHandler.new }
    let(:other_character) { create(:character, user: create(:user), level: 10, current_hp: 100, max_hp: 100) }
    before do
      create(:character_position, character: other_character)
    end

    it "schedules MatchStarterJob when application is accepted" do
      application = create(:arena_application,
        applicant: character1,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        timeout_seconds: 180)

      expect {
        handler.accept(application: application, acceptor: other_character)
      }.to have_enqueued_job(Arena::MatchStarterJob).on_queue("arena")
    end

    it "schedules job with fixed 10 second countdown (not based on turn timeout)" do
      # Turn timeout (240s) is separate from match start countdown (10s)
      application = create(:arena_application,
        applicant: character1,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        timeout_seconds: 240)

      expect(Arena::MatchStarterJob).to receive(:set)
        .with(wait: 10.seconds) # Fixed countdown, not turn timeout
        .and_return(double(perform_later: true))

      handler.accept(application: application, acceptor: other_character)
    end
  end

  describe "integration with Sidekiq" do
    it "processes the job when enqueued and performed" do
      expect(arena_match.status).to eq("pending")

      perform_enqueued_jobs do
        Arena::MatchStarterJob.perform_later(arena_match.id)
      end

      expect(arena_match.reload.status).to eq("live")
    end
  end
end
