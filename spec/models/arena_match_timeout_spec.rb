# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatch, "Turn Timeout System" do
  let(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      level_min: 1,
      level_max: 100,
      active: true)
  end
  let(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      started_at: Time.current,
      turn_timeout_seconds: 300, # 5 minutes
      current_turn_started_at: Time.current,
      current_turn_number: 1)
  end

  describe "DEFAULT_TURN_TIMEOUT" do
    it "is 300 seconds (5 minutes)" do
      expect(ArenaMatch::DEFAULT_TURN_TIMEOUT).to eq(300)
    end
  end

  describe "#turn_timed_out?" do
    context "when turn just started" do
      it "returns false" do
        expect(arena_match.turn_timed_out?).to be false
      end
    end

    context "when turn is within timeout" do
      before do
        arena_match.update!(current_turn_started_at: 4.minutes.ago)
      end

      it "returns false" do
        expect(arena_match.turn_timed_out?).to be false
      end
    end

    context "when turn exceeds timeout" do
      before do
        arena_match.update!(current_turn_started_at: 6.minutes.ago)
      end

      it "returns true" do
        expect(arena_match.turn_timed_out?).to be true
      end
    end

    context "when match is not live" do
      before do
        arena_match.update!(status: :completed)
      end

      it "returns false" do
        expect(arena_match.turn_timed_out?).to be false
      end
    end

    context "when no turn has started (nil current_turn_started_at)" do
      before do
        arena_match.update!(current_turn_started_at: nil)
      end

      it "returns false" do
        expect(arena_match.turn_timed_out?).to be false
      end
    end
  end

  describe "#seconds_until_timeout" do
    context "when turn just started" do
      it "returns approximately 300 seconds" do
        remaining = arena_match.seconds_until_timeout
        expect(remaining).to be_within(5).of(300)
      end
    end

    context "when half the time has elapsed" do
      before do
        arena_match.update!(current_turn_started_at: 150.seconds.ago)
      end

      it "returns approximately 150 seconds" do
        remaining = arena_match.seconds_until_timeout
        expect(remaining).to be_within(5).of(150)
      end
    end

    context "when timeout has passed" do
      before do
        arena_match.update!(current_turn_started_at: 400.seconds.ago)
      end

      it "returns 0 (never negative)" do
        expect(arena_match.seconds_until_timeout).to eq(0)
      end
    end

    context "when match is not live" do
      before do
        arena_match.update!(status: :completed)
      end

      it "returns nil" do
        expect(arena_match.seconds_until_timeout).to be_nil
      end
    end
  end

  describe "#start_turn!" do
    it "updates turn tracking fields" do
      arena_match.update!(current_turn_started_at: nil, current_turn_number: 0)

      arena_match.start_turn!(team: "a")

      expect(arena_match.current_turn_started_at).to be_within(1.second).of(Time.current)
      expect(arena_match.current_turn_number).to eq(1)
      expect(arena_match.current_turn_team).to eq("a")
    end

    it "increments turn number on each call" do
      arena_match.start_turn!(team: "a")
      expect(arena_match.current_turn_number).to eq(2) # Was 1, now 2

      arena_match.start_turn!(team: "b")
      expect(arena_match.current_turn_number).to eq(3)
    end

    it "schedules timeout job" do
      expect {
        arena_match.start_turn!(team: "a")
      }.to have_enqueued_job(ArenaTurnTimeoutJob)
    end
  end

  describe "#advance_turn!" do
    before do
      arena_match.update!(current_turn_team: "a")
    end

    it "switches team" do
      arena_match.advance_turn!
      expect(arena_match.current_turn_team).to eq("b")
    end

    it "resets turn start time" do
      old_time = arena_match.current_turn_started_at
      sleep(0.1) # Brief delay to ensure time difference
      arena_match.advance_turn!
      expect(arena_match.current_turn_started_at).to be >= old_time
    end

    it "increments turn number" do
      old_number = arena_match.current_turn_number
      arena_match.advance_turn!
      expect(arena_match.current_turn_number).to eq(old_number + 1)
    end

    context "when timed out" do
      it "sets timed_out flag" do
        arena_match.advance_turn!(timed_out: true)
        expect(arena_match.timed_out).to be true
      end
    end
  end

  describe ".timed_out scope" do
    let!(:fresh_match) do
      create(:arena_match,
        status: :live,
        current_turn_started_at: 1.minute.ago)
    end

    let!(:stale_match) do
      create(:arena_match,
        status: :live,
        current_turn_started_at: 10.minutes.ago)
    end

    let!(:completed_match) do
      create(:arena_match,
        status: :completed,
        current_turn_started_at: 10.minutes.ago)
    end

    it "finds only live matches past timeout" do
      results = ArenaMatch.timed_out
      expect(results).to include(stale_match)
      expect(results).not_to include(fresh_match)
      expect(results).not_to include(completed_match)
    end
  end
end
