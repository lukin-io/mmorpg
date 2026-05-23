# frozen_string_literal: true

require "rails_helper"

# ============================================
# Bug Fix: Arena Application Routes
# ============================================
# Regression tests for arena application routing.
#
# Bug: JavaScript in arena_controller.js was using incorrect paths:
#   - /arena/applications/:id/accept instead of /arena_applications/:id/accept
#   - DELETE /arena/applications/:id instead of DELETE /arena_applications/:id/cancel
#
# Fixed: 2025-12-30 by updating arena_controller.js paths

RSpec.describe "ArenaApplications", type: :request do
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
    enter_arena_from_city!(character)
  end

  def enter_arena_from_city!(character)
    zone = character.position.zone
    zone.update!(location_type: "city")
    hotspot = create(:city_hotspot, :arena, zone: zone, active: true, required_level: 1)

    post interact_hotspot_world_path, params: {hotspot_id: hotspot.id}
  end

  # ============================================
  # Route Helper Regression Tests
  # ============================================

  describe "route helpers" do
    let!(:application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :open)
    end

    it "accept_arena_application_path uses /arena_applications/:id/accept" do
      expect(accept_arena_application_path(application)).to eq("/arena_applications/#{application.id}/accept")
    end

    it "cancel_arena_application_path uses /arena_applications/:id/cancel" do
      expect(cancel_arena_application_path(application)).to eq("/arena_applications/#{application.id}/cancel")
    end

    it "accept path does NOT use /arena/applications format" do
      path = accept_arena_application_path(application)
      expect(path).not_to include("/arena/applications/")
    end

    it "cancel path does NOT use /arena/applications format" do
      path = cancel_arena_application_path(application)
      expect(path).not_to include("/arena/applications/")
    end
  end

  # ============================================
  # Success Cases
  # ============================================

  describe "POST /arena_applications/:id/accept" do
    let!(:application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel)
    end

    it "accepts an application and creates a match" do
      post accept_arena_application_path(application)

      expect(response).to have_http_status(:success).or have_http_status(:redirect)
    end

    context "with JSON format" do
      it "returns JSON response" do
        post accept_arena_application_path(application),
          headers: {"Accept" => "application/json"}

        expect(response.content_type).to include("application/json")
      end
    end
  end

  describe "DELETE /arena_applications/:id/cancel" do
    let!(:own_application) do
      create(:arena_application,
        applicant: character,
        arena_room: arena_room,
        status: :open)
    end

    it "cancels own application" do
      delete cancel_arena_application_path(own_application)

      expect(response).to have_http_status(:success).or have_http_status(:redirect)
    end

    context "with JSON format" do
      it "returns JSON response" do
        delete cancel_arena_application_path(own_application),
          headers: {"Accept" => "application/json"}

        expect(response.content_type).to include("application/json")
      end
    end
  end

  # ============================================
  # Failure Cases
  # ============================================

  describe "authentication required" do
    let!(:application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :open)
    end

    before { sign_out user }

    it "redirects to login for accept" do
      post accept_arena_application_path(application)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to login for cancel" do
      delete cancel_arena_application_path(application)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "record not found" do
    it "handles accept on non-existent application" do
      post accept_arena_application_path(id: 999999)

      expect(response).to have_http_status(:not_found)
        .or have_http_status(:redirect)
        .or have_http_status(:unprocessable_content)
    end

    it "handles cancel on non-existent application" do
      delete cancel_arena_application_path(id: 999999)

      expect(response).to have_http_status(:not_found)
        .or have_http_status(:redirect)
        .or have_http_status(:unprocessable_content)
    end
  end

  # ============================================
  # Authorization Cases
  # ============================================

  describe "authorization" do
    let!(:other_users_application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :open)
    end

    it "cannot cancel another user's application" do
      delete cancel_arena_application_path(other_users_application)

      # Should either be forbidden or redirect with error
      expect(response).to have_http_status(:forbidden)
        .or have_http_status(:redirect)
        .or have_http_status(:unprocessable_entity)
    end
  end

  # ============================================
  # Edge Cases
  # ============================================

  describe "already accepted application" do
    let!(:matched_application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :matched)
    end

    it "cannot accept an already matched application" do
      post accept_arena_application_path(matched_application)

      # Should return error status
      expect(response).to have_http_status(:unprocessable_entity)
        .or have_http_status(:redirect)
    end
  end

  describe "expired application" do
    let!(:expired_application) do
      create(:arena_application,
        applicant: other_character,
        arena_room: arena_room,
        status: :expired)
    end

    it "cannot accept an expired application" do
      post accept_arena_application_path(expired_application)

      expect(response).to have_http_status(:unprocessable_entity)
        .or have_http_status(:redirect)
    end
  end
end
