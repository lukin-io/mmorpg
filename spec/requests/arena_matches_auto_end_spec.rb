# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ArenaMatches Auto-End on View", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  include Rails.application.routes.url_helpers

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, name: "Fighter1", level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, name: "Fighter2", level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 1, level_max: 100, active: true, max_concurrent_matches: 5) }
  let!(:match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      turn_timeout_seconds: 300,
      started_at: Time.current)
  end

  let!(:participation1) { create(:arena_participation, arena_match: match, character: character1, user: user1, team: "a") }
  let!(:participation2) { create(:arena_participation, arena_match: match, character: character2, user: user2, team: "b") }

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
    sign_in user1, scope: :user
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character1)
  end

  describe "GET /arena_matches/:id (show)" do
    context "when match is normal (ongoing)" do
      it "returns success" do
        get arena_match_path(match)
        expect(response).to have_http_status(:success)
      end

      it "does not end the match" do
        expect {
          get arena_match_path(match)
        }.not_to change { match.reload.status }
      end

      it "displays live status" do
        get arena_match_path(match)
        expect(response.body).to include("LIVE")
      end
    end

    context "when opponent is defeated" do
      before do
        character2.update!(current_hp: 0)
      end

      it "auto-ends the match" do
        expect {
          get arena_match_path(match)
        }.to change { match.reload.status }.from("live").to("completed")
      end

      it "sets the correct winner" do
        get arena_match_path(match)
        expect(match.reload.winning_team).to eq("a")
      end

      it "displays completed status" do
        get arena_match_path(match)
        expect(response.body).to include("Завершен")
      end

      it "displays victory overlay for winner" do
        get arena_match_path(match)
        expect(response.body).to include("VICTORY")
      end
    end

    context "when current user is defeated" do
      before do
        character1.update!(current_hp: 0)
      end

      it "auto-ends the match" do
        expect {
          get arena_match_path(match)
        }.to change { match.reload.status }.from("live").to("completed")
      end

      it "sets the correct winner" do
        get arena_match_path(match)
        expect(match.reload.winning_team).to eq("b")
      end

      it "displays defeat overlay for loser" do
        get arena_match_path(match)
        expect(response.body).to include("DEFEAT")
      end
    end

    context "when match is stale (timed out)" do
      it "auto-ends the match after timeout period" do
        travel_to(match.started_at + 15.minutes) do
          expect {
            get arena_match_path(match)
          }.to change { match.reload.status }.from("live").to("completed")
        end
      end

      it "sets timed_out flag" do
        travel_to(match.started_at + 15.minutes) do
          get arena_match_path(match)
          expect(match.reload.timed_out).to be true
        end
      end

      it "displays completed status after timeout" do
        travel_to(match.started_at + 15.minutes) do
          get arena_match_path(match)
          expect(response.body).to include("Завершен")
        end
      end
    end

    context "when match is already completed" do
      before do
        match.update!(status: :completed, winning_team: "a", ended_at: Time.current)
      end

      it "returns success" do
        get arena_match_path(match)
        expect(response).to have_http_status(:success)
      end

      it "does not change status" do
        expect {
          get arena_match_path(match)
        }.not_to change { match.reload.status }
      end
    end

    context "when viewing as spectator" do
      let(:spectator_user) { create(:user) }
      let(:spectator_character) { create(:character, user: spectator_user, name: "Spectator", level: 5) }

      before do
        create(:character_position, character: spectator_character)
        sign_in spectator_user, scope: :user
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(spectator_character)
        character2.update!(current_hp: 0)
      end

      it "auto-ends the match even for spectators" do
        expect {
          get arena_match_path(match)
        }.to change { match.reload.status }.from("live").to("completed")
      end

      it "displays match ended instead of victory/defeat" do
        get arena_match_path(match)
        expect(response.body).to include("MATCH ENDED")
      end
    end
  end

  describe "POST /arena_matches/:id/action" do
    context "when match is normal" do
      it "processes the action and redirects" do
        post action_arena_match_path(match), params: {
          action_type: "attack",
          body_part: "torso",
          attack_type: "simple"
        }
        expect(response).to have_http_status(:redirect)
      end

      it "keeps match in live status after action" do
        post action_arena_match_path(match), params: {
          action_type: "attack",
          body_part: "torso"
        }
        expect(match.reload.status).to eq("live")
      end
    end

    context "when opponent is defeated" do
      before do
        character2.update!(current_hp: 0)
      end

      it "still processes the action (auto-end happens on show)" do
        # Note: Auto-end check happens on GET show, not on POST action
        # This tests that actions are still processed even when opponent is down
        post action_arena_match_path(match), params: {
          action_type: "attack",
          body_part: "torso"
        }
        expect(response).to redirect_to(arena_match_path(match))
      end

      it "match ends when show is called afterwards" do
        post action_arena_match_path(match), params: {
          action_type: "attack"
        }
        # Now the redirect to show will trigger auto-end
        get arena_match_path(match)
        expect(match.reload.status).to eq("completed")
      end
    end

    context "when match is stale (timed out)" do
      it "still processes action but show auto-ends afterwards" do
        travel_to(match.started_at + 15.minutes) do
          post action_arena_match_path(match), params: {
            action_type: "attack"
          }
          # Action redirects to show which triggers auto-end
          get arena_match_path(match)
          expect(match.reload.status).to eq("completed")
        end
      end
    end
  end
end
