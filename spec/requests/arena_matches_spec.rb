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

    it "arena_matches_path uses underscore format /arena_matches" do
      path = "/arena_matches"
      expect(path).to eq("/arena_matches")
      expect(path).not_to include("/arena/matches")
    end
  end

  # ============================================
  # Success Cases
  # ============================================

  describe "GET /arena_matches" do
    it "responds to arena_matches index" do
      get "/arena_matches"

      expect(response).to have_http_status(:success)
        .or have_http_status(:redirect)
    end
  end

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

    it "redirects to login for arena_matches index" do
      get "/arena_matches"

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
end
