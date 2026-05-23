# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatch, "Lifecycle and Status Transitions" do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true) }
  let(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :pending,
      match_type: :duel,
      turn_timeout_seconds: 300,
      metadata: {
        "fight_kind" => "free",
        "trauma_percent" => 30,
        "starts_at" => 2.minutes.from_now.iso8601
      })
  end

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
    create(:arena_participation, arena_match: arena_match, character: character1, user: user1, team: "a")
    create(:arena_participation, arena_match: arena_match, character: character2, user: user2, team: "b")
  end

  describe "status enum" do
    it "defines all expected statuses" do
      expect(ArenaMatch::STATUSES.keys).to contain_exactly(:pending, :matching, :live, :completed, :cancelled)
    end

    it "starts in pending status by default" do
      match = ArenaMatch.create!(match_type: :duel, arena_room: arena_room)
      expect(match.status).to eq("pending")
    end
  end

  describe "#active?" do
    it "returns true for pending matches" do
      arena_match.update!(status: :pending)
      expect(arena_match.active?).to be true
    end

    it "returns true for matching matches" do
      arena_match.update!(status: :matching)
      expect(arena_match.active?).to be true
    end

    it "returns true for live matches" do
      arena_match.update!(status: :live, started_at: Time.current)
      expect(arena_match.active?).to be true
    end

    it "returns false for completed matches" do
      arena_match.update!(status: :completed, started_at: 1.hour.ago, ended_at: Time.current)
      expect(arena_match.active?).to be false
    end

    it "returns false for cancelled matches" do
      arena_match.update!(status: :cancelled)
      expect(arena_match.active?).to be false
    end
  end

  describe "#duration" do
    context "when match has not started" do
      it "returns nil" do
        expect(arena_match.started_at).to be_nil
        expect(arena_match.duration).to be_nil
      end
    end

    context "when match is in progress" do
      it "returns elapsed time from started_at to now" do
        arena_match.update!(status: :live, started_at: 5.minutes.ago)

        expect(arena_match.duration).to be_within(5).of(300)
      end
    end

    context "when match is completed" do
      it "returns total duration from started_at to ended_at" do
        arena_match.update!(
          status: :completed,
          started_at: 1.hour.ago,
          ended_at: 50.minutes.ago
        )

        expect(arena_match.duration).to be_within(5).of(600) # 10 minutes
      end
    end
  end

  describe "#broadcast_channel" do
    it "returns the correct ActionCable channel name" do
      expect(arena_match.broadcast_channel).to eq("arena:match:#{arena_match.id}")
    end
  end

  describe "#team_participants" do
    it "returns participants for team a" do
      team_a = arena_match.team_participants("a")
      expect(team_a.count).to eq(1)
      expect(team_a.first.character).to eq(character1)
    end

    it "returns participants for team b" do
      team_b = arena_match.team_participants("b")
      expect(team_b.count).to eq(1)
      expect(team_b.first.character).to eq(character2)
    end

    it "returns empty relation for non-existent team" do
      team_c = arena_match.team_participants("c")
      expect(team_c).to be_empty
    end
  end

  describe "spectator_code" do
    it "is automatically assigned on create" do
      match = ArenaMatch.create!(match_type: :duel, arena_room: arena_room)
      expect(match.spectator_code).to be_present
    end

    it "generates an 8-character alphanumeric code" do
      match = ArenaMatch.create!(match_type: :duel, arena_room: arena_room)
      expect(match.spectator_code).to match(/\A[A-Z0-9]{8}\z/)
    end

    it "generates unique codes for different matches" do
      codes = 5.times.map { ArenaMatch.create!(match_type: :duel, arena_room: arena_room).spectator_code }
      expect(codes.uniq.size).to eq(5)
    end
  end

  describe "scopes" do
    let!(:pending_match) { create(:arena_match, status: :pending, arena_room: arena_room) }
    let!(:live_match) { create(:arena_match, status: :live, started_at: Time.current, arena_room: arena_room) }
    let!(:completed_match) { create(:arena_match, status: :completed, started_at: 1.hour.ago, ended_at: Time.current, arena_room: arena_room) }
    let!(:cancelled_match) { create(:arena_match, status: :cancelled, arena_room: arena_room) }

    describe ".active" do
      it "includes pending, matching, and live matches" do
        active_matches = ArenaMatch.active
        expect(active_matches).to include(pending_match, live_match, arena_match)
        expect(active_matches).not_to include(completed_match, cancelled_match)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        recent_matches = ArenaMatch.recent
        expect(recent_matches.first.created_at).to be >= recent_matches.last.created_at
      end
    end
  end

  describe "match creation from ApplicationHandler" do
    let(:handler) { Arena::ApplicationHandler.new }
    let!(:application) do
      create(:arena_application,
        applicant: character1,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        fight_kind: :free,
        timeout_seconds: 180,
        trauma_percent: 30)
    end

    it "creates a match in pending status" do
      result = handler.accept(application: application, acceptor: character2)

      expect(result.success?).to be true
      expect(result.match.status).to eq("pending")
    end

    it "stores starts_at in metadata" do
      result = handler.accept(application: application, acceptor: character2)

      expect(result.match.metadata["starts_at"]).to be_present
    end

    it "stores fight_kind from application" do
      result = handler.accept(application: application, acceptor: character2)

      expect(result.match.metadata["fight_kind"]).to eq("free")
    end

    it "stores trauma_percent from application as attribute" do
      result = handler.accept(application: application, acceptor: character2)

      # trauma_percent is stored as a column, not in metadata
      expect(result.match.trauma_percent).to eq(30)
    end

    it "stores turn_timeout_seconds from application as attribute" do
      result = handler.accept(application: application, acceptor: character2)

      # timeout_seconds is stored as turn_timeout_seconds column, not in metadata
      expect(result.match.turn_timeout_seconds).to eq(180)
    end
  end

  describe "status transition: pending -> live" do
    it "can transition via MatchStarterJob" do
      expect(arena_match.status).to eq("pending")

      Arena::MatchStarterJob.new.perform(arena_match.id)

      expect(arena_match.reload.status).to eq("live")
    end

    it "sets started_at during transition" do
      expect(arena_match.started_at).to be_nil

      Arena::MatchStarterJob.new.perform(arena_match.id)

      expect(arena_match.reload.started_at).to be_present
    end

    it "sets participants to in_combat" do
      Arena::MatchStarterJob.new.perform(arena_match.id)

      expect(character1.reload.in_combat).to be true
      expect(character2.reload.in_combat).to be true
    end
  end

  describe "edge cases" do
    context "match with no arena_room" do
      it "can still be created and processed" do
        match = ArenaMatch.create!(match_type: :duel, status: :pending)
        expect(match).to be_persisted

        Arena::MatchStarterJob.new.perform(match.id)
        expect(match.reload.status).to eq("live")
      end
    end

    context "concurrent job execution" do
      it "only transitions once even if job runs twice" do
        # First run transitions to live
        Arena::MatchStarterJob.new.perform(arena_match.id)
        first_started_at = arena_match.reload.started_at

        # Second run should be a no-op since match is no longer pending
        sleep(0.1) # Small delay to ensure different timestamp
        Arena::MatchStarterJob.new.perform(arena_match.id)

        expect(arena_match.reload.started_at).to eq(first_started_at)
        expect(arena_match.status).to eq("live")
      end
    end
  end
end
