# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::ApplicationHandler do
  let(:handler) { described_class.new }
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10, current_hp: 100, max_hp: 100) }
  let(:other_user) { create(:user) }
  let(:other_character) { create(:character, user: other_user, level: 10, current_hp: 100, max_hp: 100) }
  let!(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      slug: "test-arena",
      level_min: 1,
      level_max: 100,
      room_type: :challenge,
      active: true,
      max_concurrent_matches: 10)
  end
  let!(:arena_season) do
    create(:arena_season, status: :live)
  end

  before do
    create(:character_position, character: character)
    create(:character_position, character: other_character)
  end

  describe "#create" do
    let(:valid_params) do
      {
        fight_type: "duel",
        fight_kind: "free",
        timeout_seconds: 180,
        trauma_percent: 30
      }
    end

    context "with valid params" do
      it "creates an application" do
        result = handler.create(
          character: character,
          room: arena_room,
          params: valid_params
        )

        expect(result.success?).to be true
        expect(result.application).to be_persisted
        expect(result.application.applicant).to eq(character)
        expect(result.application.fight_type).to eq("duel")
      end

      it "sets correct expiration" do
        result = handler.create(
          character: character,
          room: arena_room,
          params: valid_params.merge(wait_minutes: 15)
        )

        expect(result.application.expires_at).to be_within(1.minute).of(15.minutes.from_now)
      end
    end

    context "with inaccessible room" do
      let(:high_level_room) do
        create(:arena_room, level_min: 50, level_max: 100, active: true)
      end

      it "returns error" do
        result = handler.create(
          character: character,
          room: high_level_room,
          params: valid_params
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You cannot access this arena room")
      end
    end

    context "with existing active application" do
      before do
        create(:arena_application,
          applicant: character,
          arena_room: arena_room,
          status: :open)
      end

      it "returns error" do
        result = handler.create(
          character: character,
          room: arena_room,
          params: valid_params
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You already have an active fight application")
      end
    end

    context "when room is at capacity" do
      before do
        # Set to 1 capacity and create a match to fill it
        arena_room.update!(max_concurrent_matches: 1)
        create(:arena_match, arena_room: arena_room, status: :live)
      end

      it "returns error" do
        result = handler.create(
          character: character,
          room: arena_room,
          params: valid_params
        )

        expect(result.success?).to be false
        expect(result.errors).to include("This arena room is at capacity")
      end
    end
  end

  describe "#accept" do
    let!(:application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        fight_kind: :free,
        timeout_seconds: 180,
        trauma_percent: 30)
    end

    context "with valid acceptance" do
      it "creates a match" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be true
        expect(result.match).to be_persisted
        expect(result.match.status).to eq("pending")
      end

      it "updates application status to matched" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(application.reload.status).to eq("matched")
        expect(application.matched_at).to be_present
      end

      it "creates participations for both characters" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        match = result.match
        expect(match.arena_participations.count).to eq(2)
        expect(match.characters).to include(character, other_character)
      end

      it "assigns characters to different teams" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        match = result.match
        teams = match.arena_participations.pluck(:team).uniq
        expect(teams.size).to eq(2)
        expect(teams).to contain_exactly("a", "b")
      end

      it "schedules match starter job" do
        expect(Arena::MatchStarterJob).to receive(:set)
          .with(wait: 180.seconds)
          .and_return(double(perform_later: true))

        handler.accept(
          application: application,
          acceptor: character
        )
      end
    end

    context "when acceptor cannot access application" do
      before do
        application.update!(team_level_min: 50, team_level_max: 100)
      end

      it "returns error" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You cannot accept this application")
      end
    end

    context "when trying to accept own application" do
      let!(:own_application) do
        create(:arena_application,
          applicant: character,
          arena_room: arena_room,
          status: :open)
      end

      it "returns error" do
        result = handler.accept(
          application: own_application,
          acceptor: character
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You cannot accept this application")
      end
    end

    context "when application is not open" do
      before do
        application.update!(status: :matched)
      end

      it "returns error" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You cannot accept this application")
      end
    end
  end

  describe "#cancel" do
    let!(:application) do
      create(:arena_application,
        applicant: character,
        arena_room: arena_room,
        status: :open)
    end

    context "with own application" do
      it "cancels the application" do
        result = handler.cancel(
          application: application,
          character: character
        )

        expect(result.success?).to be true
        expect(application.reload.status).to eq("cancelled")
      end
    end

    context "with another user's application" do
      it "returns error" do
        result = handler.cancel(
          application: application,
          character: other_character
        )

        expect(result.success?).to be false
        expect(result.errors).to include("You can only cancel your own applications")
      end
    end

    context "when application is not open" do
      before do
        application.update!(status: :matched)
      end

      it "returns error" do
        result = handler.cancel(
          application: application,
          character: character
        )

        expect(result.success?).to be false
        expect(result.errors).to include("This application cannot be cancelled")
      end
    end
  end
end
