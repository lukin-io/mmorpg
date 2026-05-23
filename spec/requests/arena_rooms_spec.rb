# frozen_string_literal: true

require "rails_helper"

# ============================================
# Bug Fix: Arena Room Routes
# ============================================
# Regression tests for arena room routing.
#
# Bug: JavaScript in arena_controller.js was using incorrect paths:
#   - /arena/rooms/:id instead of /arena_rooms/:id
#   - /arena/applications/:id/accept instead of /arena_applications/:id/accept
#   - /arena/applications/:id instead of /arena_applications/:id/cancel
#   - /arena/matches/:id instead of /arena_matches/:id
#
# Fixed: 2025-12-30 by updating arena_controller.js paths

RSpec.describe "ArenaRooms", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
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
  # Success Cases
  # ============================================

  describe "GET /arena_rooms/:id" do
    it "returns arena room show page successfully" do
      get arena_room_path(arena_room)

      expect(response).to have_http_status(:success)
    end

    it "displays the arena room name" do
      get arena_room_path(arena_room)

      expect(response.body).to include(arena_room.name)
    end

    it "shows level requirements" do
      get arena_room_path(arena_room)

      expect(response.body).to include("1").and include("100")
    end
  end

  # ============================================
  # Route Helper Regression Tests
  # ============================================
  # Verify the correct route helpers are available after bug fix

  describe "route helpers" do
    it "arena_room_path returns /arena_rooms/:id" do
      expect(arena_room_path(arena_room)).to eq("/arena_rooms/#{arena_room.id}")
    end

    it "arena_room_path does NOT use /arena/rooms format" do
      path = arena_room_path(arena_room)
      expect(path).not_to include("/arena/rooms/")
    end
  end

  # ============================================
  # Failure Cases
  # ============================================

  describe "authentication required" do
    before { sign_out user }

    it "redirects to login for arena_room show" do
      get arena_room_path(arena_room)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "record not found" do
    it "handles non-existent arena room gracefully" do
      get arena_room_path(id: 999999)

      # May raise 404 or redirect
      expect(response).to have_http_status(:not_found)
        .or have_http_status(:redirect)
    end
  end

  # ============================================
  # Edge Cases
  # ============================================

  describe "level restrictions" do
    let(:high_level_room) do
      create(:arena_room,
        name: "High Level Arena",
        level_min: 50,
        level_max: 100,
        active: true)
    end

    it "handles room with level restrictions" do
      get arena_room_path(high_level_room)

      # May show room or redirect if level too low
      expect(response).to have_http_status(:success)
        .or have_http_status(:redirect)
    end
  end

  describe "inactive rooms" do
    let(:inactive_room) do
      create(:arena_room,
        name: "Inactive Arena",
        active: false)
    end

    it "handles inactive room request" do
      get arena_room_path(inactive_room)

      # May show room or redirect
      expect(response).to have_http_status(:success)
        .or have_http_status(:redirect)
    end
  end
end
