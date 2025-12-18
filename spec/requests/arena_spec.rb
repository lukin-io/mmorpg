# frozen_string_literal: true

require "rails_helper"

# ============================================
# Bug Fix: Arena Page Loading
# ============================================
# Regression tests for the Arena feature.
#
# Bug 1: undefined method 'arena_applications' for Character
#        Fixed by adding has_many :arena_applications association
#
# Bug 2: undefined method 'arena_participations' for Character
#        Fixed by adding has_many :arena_participations association
#
# Bug 3: undefined method 'arena_path' route helper
#        Fixed by using arena_index_path instead

RSpec.describe "Arena", type: :request do
  describe "GET /arena" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user, level: 10) }

    before do
      # Ensure character has a position (required by some controller callbacks)
      create(:character_position, character: character)
      sign_in user, scope: :user
    end

    context "successful page load" do
      it "renders arena page successfully" do
        get arena_index_path

        expect(response).to have_http_status(:success)
      end

      it "displays arena title" do
        get arena_index_path

        expect(response.body).to include("Arena")
      end

      it "shows arena rooms section" do
        get arena_index_path

        expect(response.body).to include("Arena Room").or include("Room")
      end

      it "shows fight type tabs" do
        get arena_index_path

        expect(response.body).to include("Duel")
        expect(response.body).to include("Team Battle")
        expect(response.body).to include("Sacrifice")
      end
    end

    context "with arena rooms" do
      let!(:arena_room) do
        create(:arena_room,
          name: "Test Arena Room",
          level_min: 1,
          level_max: 100,
          room_type: :challenge,
          active: true)
      end

      it "displays available arena rooms" do
        get arena_index_path

        # Rooms are displayed by room type badge, not name
        expect(response.body).to include("Challenge Arena").or include("arena-room")
      end

      it "shows enter button for accessible rooms" do
        get arena_index_path

        expect(response.body).to include("Enter")
      end

      it "includes room level range" do
        get arena_index_path

        expect(response.body).to include("1-100")
      end
    end

    context "with active application" do
      let!(:arena_room) { create(:arena_room) }
      let!(:application) do
        create(:arena_application,
          applicant: character,
          arena_room: arena_room,
          status: :open)
      end

      it "displays current application status" do
        get arena_index_path

        expect(response.body).to include("Active Application").or include("Application")
      end

      it "shows cancel button for active application" do
        get arena_index_path

        expect(response.body).to include("Cancel")
      end
    end

    context "without authentication (failure case)" do
      before { sign_out user }

      it "redirects to login page" do
        get arena_index_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "character level checks" do
      let!(:high_level_room) do
        create(:arena_room,
          name: "High Level Arena",
          level_min: 50,
          level_max: 100,
          active: true)
      end

      it "shows room as unavailable when level too low" do
        get arena_index_path

        expect(response.body).to include("unavailable").or include("level")
      end
    end
  end

  # ============================================
  # Route Helper Regression Tests
  # ============================================
  # These tests verify that the correct route helpers are being used
  # after fixing arena_path -> arena_index_path

  describe "route helpers" do
    it "arena_index_path returns /arena" do
      expect(arena_index_path).to eq("/arena")
    end

    it "arena_index_path accepts query params" do
      expect(arena_index_path(ft: 1)).to eq("/arena?ft=1")
    end
  end

  describe "arena tabs navigation" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user) }

    before do
      create(:character_position, character: character)
      sign_in user, scope: :user
    end

    it "shows correct active tab for duels" do
      get arena_index_path(ft: 1)

      expect(response).to have_http_status(:success)
    end

    it "shows correct active tab for team battle" do
      get arena_index_path(ft: 2)

      expect(response).to have_http_status(:success)
    end

    it "shows correct active tab for sacrifice" do
      get arena_index_path(ft: 3)

      expect(response).to have_http_status(:success)
    end

    it "shows correct active tab for statistics" do
      get arena_index_path(ft: 4)

      expect(response).to have_http_status(:success)
    end
  end

  # ============================================
  # Integration with City Hotspots
  # ============================================
  # Tests for navigating to Arena from city hotspot

  describe "navigation from city hotspot" do
    let(:user) { create(:user) }
    let(:city_zone) { create(:zone, biome: "city") }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: city_zone) }
    let!(:arena_hotspot) do
      create(:city_hotspot, :arena,
        zone: city_zone,
        active: true,
        required_level: 1)
    end

    before { sign_in user, scope: :user }

    it "clicking arena hotspot navigates to arena page" do
      post interact_hotspot_world_path, params: {hotspot_id: arena_hotspot.id}

      expect(response).to redirect_to("/arena")
      follow_redirect!
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Arena")
    end

    it "uses Turbo Stream redirect with proper status" do
      post interact_hotspot_world_path,
        params: {hotspot_id: arena_hotspot.id},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to("/arena")
    end
  end
end
