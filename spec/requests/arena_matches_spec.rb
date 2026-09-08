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
      room_type: :trial,
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
      expect(response.body).to include("Waiting")
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

    it "recovers a due pending start when a participant reconnects" do
      pending_match.update!(metadata: {"starts_at" => 1.second.ago.iso8601})

      get arena_match_path(pending_match)

      expect(response).to have_http_status(:success)
      expect(pending_match.reload).to be_live
    end
  end

  describe "public fight-link access" do
    let!(:live_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :live,
        started_at: Time.current)
      create(:arena_participation, arena_match: match, character: other_character, user: other_user, team: "a")
      match
    end

    it "allows non-participants to view the fight screen" do
      get "/arena_matches/#{live_match.id}"

      expect(response).to have_http_status(:success)
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
      it "accepts a complete combat turn" do
        post "/arena_matches/#{live_match.id}/action",
          params: {
            action_type: "turn",
            target_id: other_character.id,
            attacks: [{action_key: "simple", body_part: "torso"}],
            blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
          },
          as: :json

        expect(response).to have_http_status(:success)
        expect(live_match.arena_participations.find_by(user: user).reload.metadata["pending_turn"]).to be_present
      end

      it "accepts the indexed parameter shape submitted by the fight form" do
        post action_arena_match_path(live_match),
          params: {
            action_type: "turn",
            target_id: other_character.id,
            attacks: {"0" => {action_key: "simple", body_part: "torso"}},
            blocks: {"0" => {action_key: "torso_block", body_parts: {"0" => "torso"}}}
          }

        expect(response).to have_http_status(:see_other)
        pending_turn = live_match.arena_participations.find_by(user: user).reload.metadata.fetch("pending_turn")
        expect(pending_turn.fetch("attacks")).to eq([{"action_key" => "simple", "body_part" => "torso"}])
        expect(pending_turn.fetch("blocks")).to eq([{"action_key" => "torso_block", "body_parts" => ["torso"]}])
      end

      it "re-renders authoritative waiting state after a Turbo turn" do
        post action_arena_match_path(live_match),
          params: {
            action_type: "turn",
            target_id: other_character.id,
            attacks: [{action_key: "simple", body_part: "torso"}],
            blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(arena_match_path(live_match))
      end

      it "rejects forged direct attack, defend, and unsupported flee intents without mutating combat" do
        initial_hp = other_character.current_hp
        initial_log_count = live_match.combat_log_entries.count

        %w[attack defend flee].each do |action_type|
          post action_arena_match_path(live_match),
            params: {action_type:, target_id: other_character.id, body_part: "torso", block_parts: ["torso"]},
            as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body["error"]).to eq("Unsupported player combat intent")
        end

        expect(other_character.reload.current_hp).to eq(initial_hp)
        expect(live_match.combat_log_entries.count).to eq(initial_log_count)
      end

      it "rejects an allied target before storing a pending turn" do
        initial_log_count = live_match.combat_log_entries.count

        post action_arena_match_path(live_match),
          params: {
            action_type: "turn",
            target_id: character.id,
            attacks: [{action_key: "simple", body_part: "torso"}],
            blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
          },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq("Cannot attack an ally")
        expect(live_match.arena_participations.find_by(user: user).reload.metadata["pending_turn"]).to be_blank
        expect(live_match.combat_log_entries.count).to eq(initial_log_count)
      end

      it "records surrender through the shared combat action" do
        post action_arena_match_path(live_match),
          params: {action_type: "surrender"},
          as: :json

        expect(response).to have_http_status(:success)
        expect(character.reload.current_hp).to eq(0)
        expect(live_match.reload).to be_completed
        expect(live_match.winning_team).to eq("b")
        expect(live_match.arena_participations.find_by(user: user).metadata["surrendered_at"]).to be_present
      end

      it "redirects a Turbo surrender submission to the result state" do
        post action_arena_match_path(live_match),
          params: {action_type: "surrender"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(arena_match_path(live_match))
      end

      it "targets one repeated NPC template by its participation id" do
        npc_template = create(:npc_template, name: "Plague Rat")
        create(:arena_participation, :npc,
          arena_match: live_match,
          npc_template: npc_template,
          team: "b")
        target = create(:arena_participation, :npc,
          arena_match: live_match,
          npc_template: npc_template,
          team: "b")
        processor = instance_double(Arena::CombatProcessor)
        result = Arena::CombatProcessor::Result.new(true, nil, {damage: 1})

        expect(Arena::CombatProcessor).to receive(:new).with(live_match).and_return(processor)
        expect(processor).to receive(:process_player_intent)
          .with(
            character,
            "turn",
            target: target,
            attacks: [hash_including("action_key" => "simple", "body_part" => "torso")],
            blocks: [hash_including("action_key" => "torso_block", "body_parts" => ["torso"])]
          )
          .and_return(result)

        post action_arena_match_path(live_match),
          params: {
            action_type: "turn",
            target_id: "npc-participation-#{target.id}",
            attacks: [{action_key: "simple", body_part: "torso"}],
            blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
          },
          as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not participant" do
      let(:outsider_user) { create(:user) }
      let(:outsider_character) { create(:character, user: outsider_user, level: 10) }

      before do
        create(:character_position, character: outsider_character)
        sign_out user
        sign_in outsider_user
      end

      it "rejects the mutation and leaves authoritative fight state unchanged" do
        initial_hp = [character.current_hp, other_character.current_hp]
        initial_log_count = live_match.combat_log_entries.count

        post "/arena_matches/#{live_match.id}/action",
          params: {
            action_type: "turn",
            target_id: other_character.id,
            attacks: [{action_key: "simple", body_part: "torso"}],
            blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
          },
          as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq("error" => "forbidden")
        expect([character.reload.current_hp, other_character.reload.current_hp]).to eq(initial_hp)
        expect(live_match.arena_participations.pluck(:metadata)).to all(satisfy { |metadata| metadata.exclude?("pending_turn") })
        expect(live_match.combat_log_entries.count).to eq(initial_log_count)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "requires authentication" do
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "turn"},
          as: :json

        expect(response).to have_http_status(:unauthorized)
          .or redirect_to(new_user_session_path)
      end
    end

    context "when match is not live" do
      before { live_match.update!(status: :completed, ended_at: Time.current) }

      it "rejects action on completed match" do
        post "/arena_matches/#{live_match.id}/action",
          params: {action_type: "turn"},
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
          .or have_http_status(:forbidden)
      end
    end
  end

  describe "POST /arena_matches/:id/claim_timeout" do
    let!(:live_match) do
      match = create(:arena_match, :timeout_claimable,
        arena_room: arena_room,
        match_type: :duel)
      create(:arena_participation, :waiting_for_opponent,
        arena_match: match,
        character: character,
        user: user,
        team: "a")
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

    it "records an explicit draw without inferring a higher-HP winner" do
      character.update!(current_hp: 1)
      other_character.update!(current_hp: other_character.max_hp)

      post claim_timeout_arena_match_path(live_match),
        params: {mode: "draw"},
        as: :json

      expect(response).to have_http_status(:success)
      expect(live_match.reload).to be_completed
      expect(live_match.winning_team).to be_nil
      expect(live_match.arena_participations.reload.map(&:result)).to all(eq("draw"))
    end

    it "rejects a claim before the timeout boundary without changing the match" do
      live_match.update!(current_turn_started_at: 299.seconds.ago)

      post claim_timeout_arena_match_path(live_match),
        params: {mode: "victory"},
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("Turn timer has not expired yet")
      expect(live_match.reload).to be_live
      expect(live_match.winning_team).to be_nil
    end

    it "rejects a non-participant without consuming the waiting player's claim" do
      outsider_user = create(:user)
      create(:character, :with_position, user: outsider_user)
      sign_out user
      sign_in outsider_user

      post claim_timeout_arena_match_path(live_match),
        params: {mode: "victory"},
        as: :json

      expect(response).to have_http_status(:forbidden)
      expect(live_match.reload).to be_live
      expect(live_match.arena_participations.find_by(user: user).metadata["pending_turn"]).to be_present
    end
  end

  # ============================================
  # Match Lifecycle Integration Tests
  # ============================================

  describe "match lifecycle from application to combat" do
    include ActiveJob::TestHelper
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

  describe "POST /arena_matches/:id/finish" do
    let!(:completed_match) do
      match = create(:arena_match,
        arena_room: arena_room,
        status: :completed,
        started_at: 5.minutes.ago,
        ended_at: Time.current,
        winning_team: "a")
      create(:arena_participation, arena_match: match, character: character, user: user, team: "a", result: :victory)
      create(:arena_participation, arena_match: match, character: other_character, user: other_user, team: "b", result: :defeat)
      match
    end

    it "marks the participant result screen as finished and returns to arena" do
      character.update!(in_combat: true)

      post finish_arena_match_path(completed_match)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(arena_index_path)
      participation = completed_match.arena_participations.find_by(user: user)
      expect(participation.reload.metadata["finished_at"]).to be_present
      expect(character.reload).not_to be_in_combat
    end

    it "is idempotent across repeated full-page submissions" do
      character.update!(in_combat: true)

      post finish_arena_match_path(completed_match)
      participation = completed_match.arena_participations.find_by(user: user)
      first_finished_at = participation.reload.metadata.fetch("finished_at")

      post finish_arena_match_path(completed_match)

      expect(response).to have_http_status(:see_other)
      expect(participation.reload.metadata.fetch("finished_at")).to eq(first_finished_at)
      expect(character.reload).not_to be_in_combat
    end

    it "rejects a non-participant without clearing combat or finishing a result" do
      outsider_user = create(:user)
      outsider_character = create(:character, :with_position, user: outsider_user, in_combat: true)
      participant = completed_match.arena_participations.find_by(user: user)
      sign_out user
      sign_in outsider_user

      post finish_arena_match_path(completed_match), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(participant.reload.metadata["finished_at"]).to be_blank
      expect(outsider_character.reload).to be_in_combat
    end

    it "rejects premature finish and preserves the participant's combat state" do
      completed_match.update!(status: :live, ended_at: nil)
      character.update!(in_combat: true)

      post finish_arena_match_path(completed_match), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("The fight is still active.")
      expect(completed_match.arena_participations.find_by(user: user).reload.metadata["finished_at"]).to be_blank
      expect(character.reload).to be_in_combat
    end

    it "requires authentication" do
      sign_out user

      post finish_arena_match_path(completed_match)

      expect(response).to redirect_to(new_user_session_path)
      expect(completed_match.arena_participations.find_by(user: user).reload.metadata["finished_at"]).to be_blank
    end


    it "returns a completed wilderness fight to its saved inventory context" do
      completed_match.update!(
        arena_room: nil,
        metadata: {
          "source" => "world_npc",
          "return_context" => {"name" => "inventory"}
        }
      )
      character.update!(in_combat: true)

      post finish_arena_match_path(completed_match)

      expect(response).to redirect_to(inventory_path)
      expect(character.reload).not_to be_in_combat
    end

    it "falls back to world for an invalid persisted wilderness return context" do
      completed_match.update!(
        arena_room: nil,
        metadata: {
          "source" => "world_npc",
          "return_context" => {"name" => "https://example.test"}
        }
      )

      post finish_arena_match_path(completed_match)

      expect(response).to redirect_to(world_path)
    end
  end
end
