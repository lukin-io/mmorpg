# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena Match Redirect", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:character_a) { create(:character, user: user_a, level: 15) }
  let(:character_b) { create(:character, user: user_b, level: 15) }
  let(:arena_room) { create(:arena_room, level_min: 10, level_max: 25, max_concurrent_matches: 5) }
  let!(:arena_season) { create(:arena_season, status: :live) }

  describe "GET /arena" do
    context "when user has an active match" do
      let(:arena_match) do
        create(:arena_match, arena_room: arena_room, status: :live, arena_season: arena_season)
      end

      before do
        create(:arena_participation, arena_match: arena_match, character: character_a, user: user_a, team: "a")
        create(:arena_participation, arena_match: arena_match, character: character_b, user: user_b, team: "b")
      end

      it "redirects user A to the active match" do
        sign_in user_a, scope: :user
        get arena_index_path
        expect(response).to redirect_to(arena_match_path(arena_match))
      end

      it "redirects user B to the active match" do
        sign_in user_b, scope: :user
        get arena_index_path
        expect(response).to redirect_to(arena_match_path(arena_match))
      end
    end

    context "when user has a pending match" do
      let(:arena_match) do
        create(:arena_match, arena_room: arena_room, status: :pending, arena_season: arena_season)
      end

      before do
        create(:arena_participation, arena_match: arena_match, character: character_a, user: user_a, team: "a")
      end

      it "redirects to the pending match" do
        sign_in user_a, scope: :user
        get arena_index_path
        expect(response).to redirect_to(arena_match_path(arena_match))
      end
    end

    context "when user has no active match" do
      before { character_a } # Ensure character is created

      it "shows the arena lobby" do
        sign_in user_a, scope: :user
        get arena_index_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /arena_rooms/:id" do
    context "when user has an active match in any room" do
      let(:arena_match) do
        create(:arena_match, arena_room: arena_room, status: :live, arena_season: arena_season)
      end

      before do
        create(:arena_participation, arena_match: arena_match, character: character_a, user: user_a, team: "a")
      end

      it "redirects to the active match" do
        sign_in user_a, scope: :user
        get arena_room_path(arena_room)
        expect(response).to redirect_to(arena_match_path(arena_match))
      end
    end

    context "when user has no active match" do
      before { character_a } # Ensure character is created

      it "shows the room page" do
        sign_in user_a, scope: :user
        get arena_room_path(arena_room)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
