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
        handler.accept(
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

      it "schedules match starter job with fixed countdown" do
        # Match countdown is fixed at 10 seconds (not the turn timeout)
        expect(Arena::MatchStarterJob).to receive(:set)
          .with(wait: 10.seconds)
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

    # ============================================
    # HP Recovery Gate Tests (Bug Fix Coverage)
    # ============================================
    # Ensures characters with low HP cannot accept applications

    context "when acceptor has insufficient HP" do
      before do
        character.update!(current_hp: 30, max_hp: 100) # 30% HP, below 50% threshold
      end

      it "returns HP recovery error" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be false
        expect(result.errors.first).to include("cannot accept this application")
      end
    end

    context "when acceptor has exactly minimum HP" do
      before do
        character.update!(current_hp: 50, max_hp: 100) # 50% HP, at threshold
      end

      it "allows acceptance" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be true
      end
    end

    context "when acceptor has above minimum HP" do
      before do
        character.update!(current_hp: 75, max_hp: 100) # 75% HP
      end

      it "allows acceptance" do
        result = handler.accept(
          application: application,
          acceptor: character
        )

        expect(result.success?).to be true
      end
    end

    # ============================================
    # Match Scheduling Tests (Bug Fix Coverage)
    # ============================================
    # Ensures MatchStarterJob is properly scheduled

    context "job scheduling" do
      it "schedules MatchStarterJob on arena queue" do
        expect {
          handler.accept(application: application, acceptor: character)
        }.to have_enqueued_job(Arena::MatchStarterJob).on_queue("arena")
      end

      it "schedules job with fixed countdown regardless of turn timeout" do
        # Turn timeout (240s) is separate from match start countdown (10s)
        application.update!(timeout_seconds: 240)

        expect(Arena::MatchStarterJob).to receive(:set)
          .with(wait: 10.seconds) # Fixed countdown, not turn timeout
          .and_return(double(perform_later: true))

        handler.accept(application: application, acceptor: character)
      end

      it "stores starts_at in match metadata with 10 second countdown" do
        result = handler.accept(application: application, acceptor: character)

        expect(result.match.metadata["starts_at"]).to be_present
        starts_at = Time.parse(result.match.metadata["starts_at"])
        # Match starts in 10 seconds (fixed countdown)
        expect(starts_at).to be_within(5.seconds).of(10.seconds.from_now)
      end
    end

    # ============================================
    # Broadcast Tests (Bug Fix Coverage)
    # ============================================
    # Ensures both participants receive match notification

    context "broadcasting match created" do
      it "broadcasts with participant_ids for client-side detection" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "arena:room:#{arena_room.id}",
          hash_including(
            type: "match_created",
            participant_ids: array_including(character.id, other_character.id),
            countdown: 10,
            redirect_url: an_instance_of(String)
          )
        )

        # Also expect user notifications
        expect(ActionCable.server).to receive(:broadcast).with(
          "user:#{user.id}:notifications",
          hash_including(type: "arena_match_starting")
        )
        expect(ActionCable.server).to receive(:broadcast).with(
          "user:#{other_user.id}:notifications",
          hash_including(type: "arena_match_starting")
        )

        handler.accept(application: application, acceptor: character)
      end

      it "broadcasts acceptor_application_id for removing stale applications" do
        expect(ActionCable.server).to receive(:broadcast).with(
          "arena:room:#{arena_room.id}",
          hash_including(
            type: "match_created",
            application_id: application.id,
            acceptor_application_id: an_instance_of(Integer) # Acceptor's application ID
          )
        ).at_least(:once)

        allow(ActionCable.server).to receive(:broadcast) # Allow other broadcasts

        handler.accept(application: application, acceptor: character)
      end
    end

    # ============================================
    # NPC Application Tests
    # ============================================

    context "with NPC application" do
      let(:npc_template) { create(:npc_template, name: "Training Dummy", level: 5, role: "arena_bot") }
      let!(:npc_application) do
        create(:arena_application,
          applicant: nil,
          npc_template: npc_template,
          arena_room: arena_room,
          status: :open,
          fight_type: :duel,
          timeout_seconds: 120)
      end

      it "accepts NPC application and starts the fight immediately" do
        expect(Arena::MatchStarterJob).not_to receive(:set)

        result = handler.accept_npc_application(
          application: npc_application,
          acceptor: character
        )

        expect(result.success?).to be true
        expect(result.match).to be_live
        expect(character.reload.in_combat?).to be true
      end

      it "creates NPC participation" do
        result = handler.accept_npc_application(
          application: npc_application,
          acceptor: character
        )

        match = result.match
        npc_participation = match.arena_participations.find_by(npc_template: npc_template)
        expect(npc_participation).to be_present
        expect(npc_participation.team).to eq("b")
      end

      it "initializes NPC HP in metadata" do
        result = handler.accept_npc_application(
          application: npc_application,
          acceptor: character
        )

        npc_participation = result.match.arena_participations.find_by(npc_template: npc_template)
        # HP is calculated from level via combat_stats, not stored as 'health'
        expected_hp = npc_template.combat_stats[:hp]
        expect(npc_participation.metadata["current_hp"]).to eq(expected_hp)
        expect(npc_participation.metadata["max_hp"]).to eq(expected_hp)
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
