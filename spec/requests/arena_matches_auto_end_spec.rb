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
  let(:turn_params) do
    {
      action_type: "turn",
      target_id: character2.id,
      attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
    }
  end

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
        expect(response.body).to include("Live")
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
        expect(response.body).to include("Finished")
      end

      it "displays victory overlay for winner" do
        get arena_match_path(match)
        expect(response.body).to include("Victory")
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
        expect(response.body).to include("Defeat")
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
          expect(response.body).to include("Finished")
        end
      end
    end

    context "when a wilderness fight reaches its displayed five-minute deadline" do
      before do
        match.update!(metadata: {"source" => "world_npc", "fight_timeout_seconds" => 300})
      end

      it "renders the timeout result at the exact deadline" do
        travel_to(match.started_at + 300.seconds, with_usec: true) do
          get arena_match_path(match)

          expect(response).to have_http_status(:success)
          expect(match.reload).to be_completed
          expect(match).to be_timed_out
          expect(response.body).to include("Finished")
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

    context "when viewing from a public fight link" do
      let(:viewer_user) { create(:user) }
      let(:viewer_character) { create(:character, user: viewer_user, name: "Viewer", level: 5) }

      before do
        create(:character_position, character: viewer_character)
        sign_in viewer_user, scope: :user
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(viewer_character)
        character2.update!(current_hp: 0)
      end

      it "auto-ends the match from a public fight-link view" do
        expect {
          get arena_match_path(match)
        }.to change { match.reload.status }.from("live").to("completed")
      end

      it "displays match ended instead of victory/defeat" do
        get arena_match_path(match)
        expect(response.body).to include("Fight finished")
      end
    end
  end

  describe "POST /arena_matches/:id/action" do
    context "when match is normal" do
      it "processes the action and redirects" do
        post action_arena_match_path(match), params: turn_params
        expect(response).to have_http_status(:redirect)
      end

      it "keeps match in live status after action" do
        post action_arena_match_path(match), params: turn_params
        expect(match.reload.status).to eq("live")
      end
    end

    context "when opponent is defeated" do
      before do
        character2.update!(current_hp: 0)
      end

      it "ends the match before accepting another combat intent" do
        expect {
          post action_arena_match_path(match), params: turn_params
        }.not_to change { match.reload.current_turn_number }

        expect(response).to redirect_to(arena_match_path(match))
        expect(match).to be_completed
        expect(match.winning_team).to eq("a")
      end
    end

    context "when match is stale (timed out)" do
      it "ends the match before accepting another combat intent" do
        travel_to(match.started_at + 15.minutes) do
          expect {
            post action_arena_match_path(match), params: turn_params
          }.not_to change { match.reload.current_turn_number }

          expect(response).to redirect_to(arena_match_path(match))
          expect(match).to be_completed
          expect(match).to be_timed_out
        end
      end
    end

    context "when a wilderness fight deadline has elapsed" do
      before do
        match.update!(metadata: {"source" => "world_npc", "fight_timeout_seconds" => 300})
      end

      it "ends the fight before accepting another combat intent" do
        travel_to(match.started_at + 300.seconds, with_usec: true) do
          expect {
            post action_arena_match_path(match), params: turn_params
          }.not_to change { match.reload.current_turn_number }

          expect(response).to redirect_to(arena_match_path(match))
          expect(match).to be_completed
          expect(match).to be_timed_out
        end
      end
    end
  end

  describe "POST /arena_matches/:id/claim_timeout" do
    context "when the wilderness fight deadline has elapsed" do
      before do
        match.update!(
          current_turn_started_at: 301.seconds.ago,
          metadata: {"source" => "world_npc", "fight_timeout_seconds" => 300}
        )
        participation1.update!(metadata: {
          "pending_turn" => {
            "turn_number" => match.current_turn_number,
            "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
            "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}],
            "skills" => [],
            "total_ap" => 75
          }
        })
      end

      it "finalizes the global timeout as a draw before a player can claim victory" do
        travel_to(match.started_at + 300.seconds, with_usec: true) do
          post claim_timeout_arena_match_path(match), params: {mode: "victory"}, as: :json

          expect(response).to have_http_status(:unprocessable_content)
          expect(match.reload).to be_completed
          expect(match).to be_timed_out
          expect(match.winning_team).to be_nil
        end
      end
    end
  end
end
