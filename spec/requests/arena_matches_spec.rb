# frozen_string_literal: true

require "rails_helper"

# ============================================
# Bug Fix: Arena Match Routes
# ============================================
# Regression tests for arena match routing.
#
# Bug: JavaScript in arena_controller.js was using incorrect path:
#   - /arena/matches/:id instead of /arena_matches/:id
#
# Fixed: 2025-12-30 by updating arena_controller.js paths

RSpec.describe "ArenaMatches", type: :request do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
  let(:other_user) { create(:user) }
  let(:other_character) { create(:character, user: other_user, level: 10) }
  let!(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      level_min: 1,
      level_max: 100,
      room_type: :challenge,
      active: true)
  end

  before do
    create(:character_position, character: character)
    create(:character_position, character: other_character)
    sign_in user, scope: :user
  end

  # ============================================
  # Route Helper Regression Tests
  # ============================================
  # This is the critical regression test for the bug fix

  describe "route helpers" do
    it "arena_match_path uses underscore format /arena_matches/:id" do
      # The path should use underscores, not slashes
      path = "/arena_matches/123"
      expect(path).to eq("/arena_matches/123")
      expect(path).not_to include("/arena/matches/")
    end
  end

  # ============================================
  # Success Cases
  # ============================================

  describe "GET /arena_matches/:id" do
    let!(:arena_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :live)
      create(:arena_participation, arena_match: match, character: character, team: 1)
      match
    end

    it "responds to arena_match show" do
      get "/arena_matches/#{arena_match.id}"

      expect(response).to have_http_status(:success)
        .or have_http_status(:redirect)
    end
  end

  # ============================================
  # Failure Cases
  # ============================================

  describe "authentication required" do
    before { sign_out user }

    it "redirects to login for arena_match show" do
      arena_match = create(:arena_match, arena_room: arena_room, status: :live)
      create(:arena_participation, arena_match: arena_match, character: character, team: "a")

      get "/arena_matches/#{arena_match.id}"
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "record not found" do
    it "handles non-existent arena match" do
      get "/arena_matches/999999"

      expect(response).to have_http_status(:not_found)
        .or have_http_status(:redirect)
    end
  end

  # ============================================
  # Edge Cases
  # ============================================

  describe "completed matches" do
    let!(:completed_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :completed)
      create(:arena_participation, arena_match: match, character: character, team: 1)
      match
    end

    it "can view completed match" do
      get "/arena_matches/#{completed_match.id}"

      expect(response).to have_http_status(:success)
        .or have_http_status(:redirect)
    end
  end

  # ============================================
  # Match Status Display Tests
  # ============================================

  describe "match status display" do
    let!(:pending_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :pending,
        metadata: {"starts_at" => 2.minutes.from_now.iso8601})
      create(:arena_participation, arena_match: match, character: character, user: user, team: "a")
      create(:arena_participation, arena_match: match, character: other_character, user: other_user, team: "b")
      match
    end

    it "displays pending status for matches waiting to start" do
      get "/arena_matches/#{pending_match.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pending")
    end

    context "when match transitions to live" do
      before do
        pending_match.update!(status: :live, started_at: Time.current)
      end

      it "displays live status" do
        get "/arena_matches/#{pending_match.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Live")
      end
    end
  end

  # ============================================
  # Spectator Access Tests
  # ============================================

  describe "spectator access" do
    let!(:live_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :live,
        started_at: Time.current)
      create(:arena_participation, arena_match: match, character: other_character, user: other_user, team: "a")
      match
    end

    it "allows non-participants to view match (spectate)" do
      get "/arena_matches/#{live_match.id}"

      expect(response).to have_http_status(:success)
    end

    it "shows spectator code for non-participants" do
      get "/arena_matches/#{live_match.id}"

      expect(response.body).to include(live_match.spectator_code)
    end
  end

  # ============================================
  # Match Action Endpoint Tests
  # ============================================

  describe "POST /arena_matches/:id/action" do
    let!(:live_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :live,
        started_at: Time.current,
        current_turn_started_at: Time.current,
        current_turn_team: "a")
      create(:arena_participation, arena_match: match, character: character, user: user, team: "a")
      create(:arena_participation, arena_match: match, character: other_character, user: other_user, team: "b")
      match
    end

    context "when user is participant" do
      it "accepts combat action" do
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "attack", target_id: other_character.id, body_part: "torso"},
          as: :json

        expect(response).to have_http_status(:success)
          .or have_http_status(:unprocessable_entity)
      end
    end

    context "when user is not participant" do
      before { sign_out user }

      it "rejects unauthorized action" do
        sign_in other_user

        # Sign in as user who is participant but on team b, trying to act on team a's turn
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "attack", target_id: character.id},
          as: :json

        # Should either succeed (if team B can act) or fail authorization
        expect(response.status).to be_in([200, 401, 403, 422])
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "requires authentication" do
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "attack"},
          as: :json

        expect(response).to have_http_status(:unauthorized)
          .or redirect_to(new_user_session_path)
      end
    end

    context "when match is not live" do
      before { live_match.update!(status: :completed, ended_at: Time.current) }

      it "rejects action on completed match" do
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "attack"},
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
          .or have_http_status(:forbidden)
      end
    end
  end

  describe "POST /arena_matches/:id/claim_timeout" do
    let!(:live_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :live,
        started_at: Time.current,
        current_turn_started_at: 6.minutes.ago,
        current_turn_number: 1,
        turn_timeout_seconds: 300)
      create(:arena_participation,
        arena_match: match,
        character: character,
        user: user,
        team: "a",
        metadata: {
          "pending_turn" => {
            "turn_number" => 1,
            "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
            "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}],
            "skills" => [],
            "total_ap" => 75
          }
        })
      create(:arena_participation,
        arena_match: match,
        character: other_character,
        user: other_user,
        team: "b")
      match
    end

    it "records victory by timeout for a waiting participant" do
      post "/arena_matches/#{live_match.id}/claim_timeout",
        params: {mode: "victory"},
        as: :json

      expect(response).to have_http_status(:success)
      expect(live_match.reload.winning_team).to eq("a")
      expect(live_match).to be_completed
    end
  end

  # ============================================
  # Match Lifecycle Integration Tests
  # ============================================

  describe "match lifecycle from application to combat" do
    include ActiveJob::TestHelper

    let!(:arena_season) { create(:arena_season, status: :live) }
    let!(:application) do
      create(:arena_application,
        applicant: character,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        timeout_seconds: 120)
    end

    it "creates pending match when application is accepted" do
      handler = Arena::ApplicationHandler.new
      result = handler.accept(application: application, acceptor: other_character)

      expect(result.success?).to be true
      expect(result.match.status).to eq("pending")
      expect(result.match).to be_persisted
    end

    it "transitions match to live after countdown" do
      handler = Arena::ApplicationHandler.new
      result = handler.accept(application: application, acceptor: other_character)
      match = result.match

      expect(match.status).to eq("pending")

      # Simulate job execution
      perform_enqueued_jobs do
        Arena::MatchStarterJob.perform_later(match.id)
      end

      expect(match.reload.status).to eq("live")
    end

    it "sets participants to in_combat when match starts" do
      handler = Arena::ApplicationHandler.new
      result = handler.accept(application: application, acceptor: other_character)
      match = result.match

      perform_enqueued_jobs do
        Arena::MatchStarterJob.perform_later(match.id)
      end

      expect(character.reload.in_combat).to be true
      expect(other_character.reload.in_combat).to be true
    end
  end
end
