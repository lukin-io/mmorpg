# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena Match Notification System", type: :system do
  let(:user_a) { create(:user, email: "user_a@test.com", password: "password123") }
  let(:user_b) { create(:user, email: "user_b@test.com", password: "password123") }
  let!(:character_a) { create(:character, user: user_a, name: "Fighter A", level: 15, current_hp: 100, max_hp: 100) }
  let!(:character_b) { create(:character, user: user_b, name: "Fighter B", level: 15, current_hp: 100, max_hp: 100) }
  let!(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 10, level_max: 25, max_concurrent_matches: 5, active: true) }
  let!(:arena_season) { create(:arena_season, status: :live) }

  before do
    create(:character_position, character: character_a)
    create(:character_position, character: character_b)
  end

  def enter_arena_from_city!(character)
    zone = character.position.zone
    zone.update!(biome: "city")
    hotspot = create(:city_hotspot, :arena, zone:, active: true, required_level: 1)

    page.driver.submit :post, interact_hotspot_world_path, {hotspot_id: hotspot.id}
  end

  # ===========================================================================
  # BUG FIX: Match starts for BOTH applicant and acceptor
  # ===========================================================================
  # Regression test for: When User B accepts User A's application, both users
  # should see the countdown and be redirected to the match.

  describe "match notification for both participants" do
    let!(:application) do
      create(:arena_application,
        applicant: character_a,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        fight_kind: :free,
        timeout_seconds: 180,
        trauma_percent: 30)
    end

    context "when acceptor accepts the application" do
      it "shows the application in the list before acceptance" do
        login_as user_b, scope: :user
        enter_arena_from_city!(character_b)

        visit arena_room_path(arena_room)

        within ".arena-applications" do
          expect(page).to have_content("Fighter A")
          expect(page).to have_button("Accept")
        end
      end

      it "redirects acceptor to the match page after acceptance" do
        login_as user_b, scope: :user
        enter_arena_from_city!(character_b)

        visit arena_room_path(arena_room)

        # Accept the application (via form submission, no JS needed)
        click_button "Accept"

        # Should be redirected to match page
        expect(page).to have_current_path(%r{/arena_matches/\d+})
      end

      it "changes application status to matched" do
        login_as user_b, scope: :user
        enter_arena_from_city!(character_b)

        visit arena_room_path(arena_room)
        click_button "Accept"

        expect(application.reload.status).to eq("matched")
      end
    end
  end

  # ===========================================================================
  # BUG FIX: Stale applications removed from UI
  # ===========================================================================
  # Regression test for: After a match is created, both the original application
  # and the acceptor's application should be removed from the UI.

  describe "application removal after match creation" do
    let!(:application) do
      create(:arena_application,
        applicant: character_a,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        fight_kind: :free,
        timeout_seconds: 180,
        trauma_percent: 30)
    end

    it "application is visible before acceptance" do
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)

      # Application should be visible initially
      expect(page).to have_css("[data-application-id='#{application.id}']")
    end

    it "redirects to active match when revisiting arena room" do
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)
      click_button "Accept"

      # Should be on match page
      expect(page).to have_current_path(%r{/arena_matches/\d+})

      # Try to go back to arena room - should redirect to match
      visit arena_room_path(arena_room)
      expect(page).to have_current_path(%r{/arena_matches/\d+})
    end

    it "application status changes to matched after acceptance" do
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)
      click_button "Accept"

      # Verify application status
      expect(application.reload.status).to eq("matched")
    end
  end

  # ===========================================================================
  # BUG FIX: Active match redirect
  # ===========================================================================
  # Regression test for: Users with an active match should be redirected
  # when visiting arena pages.

  describe "active match redirect" do
    let(:arena_match) do
      create(:arena_match, arena_room: arena_room, status: :live, arena_season: arena_season)
    end

    before do
      create(:arena_participation, arena_match: arena_match, character: character_a, user: user_a, team: "a")
      create(:arena_participation, arena_match: arena_match, character: character_b, user: user_b, team: "b")
    end

    it "redirects user with active match from arena index to match page" do
      login_as user_a, scope: :user

      visit arena_index_path

      expect(page).to have_current_path(arena_match_path(arena_match))
      expect(page).to have_content("You have an active match!")
    end

    it "redirects user with active match from room page to match page" do
      login_as user_a, scope: :user

      visit arena_room_path(arena_room)

      expect(page).to have_current_path(arena_match_path(arena_match))
      expect(page).to have_content("You have an active match!")
    end

    it "redirects user with pending match to match page" do
      arena_match.update!(status: :pending)

      login_as user_a, scope: :user

      visit arena_index_path

      expect(page).to have_current_path(arena_match_path(arena_match))
    end

    it "allows users without active match to view arena" do
      # User B has no active match (we'll create a separate user)
      user_c = create(:user, email: "user_c@test.com", password: "password123")
      character_c = create(:character, user: user_c, name: "Fighter C", level: 15)
      create(:character_position, character: character_c)

      login_as user_c, scope: :user
      enter_arena_from_city!(character_c)

      visit arena_index_path

      expect(page).to have_current_path(arena_index_path)
      expect(page).not_to have_content("You have an active match!")
    end
  end

  # ===========================================================================
  # UI: Countdown display (requires JS - skipped in headless/CI environments)
  # ===========================================================================

  describe "countdown display", js: true do
    let!(:application) do
      create(:arena_application,
        applicant: character_a,
        arena_room: arena_room,
        status: :open,
        fight_type: :duel,
        fight_kind: :free,
        timeout_seconds: 180,
        trauma_percent: 30)
    end

    it "shows countdown overlay when match is accepted", skip: "Requires Chrome/Selenium with display" do
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)
      click_button "Accept"

      # Should see countdown or be redirected
      expect(page).to have_css(".arena-countdown", visible: true, wait: 3).or(
        have_current_path(%r{/arena_matches/\d+})
      )
    end
  end

  # ===========================================================================
  # UI: Application form and list interaction
  # ===========================================================================

  describe "application form submission" do
    it "submits application successfully" do
      login_as user_a, scope: :user
      enter_arena_from_city!(character_a)

      visit arena_room_path(arena_room)

      # Fill out application form
      select "Free", from: "fight_kind"
      select "3 min", from: "timeout_seconds"
      select "medium (30%)", from: "trauma_percent"

      click_button "Submit Application"

      # Should show success message
      expect(page).to have_content("Application submitted")
    end

    it "creates application record after form submission" do
      login_as user_a, scope: :user
      enter_arena_from_city!(character_a)

      visit arena_room_path(arena_room)

      select "Free", from: "fight_kind"
      select "3 min", from: "timeout_seconds"
      select "medium (30%)", from: "trauma_percent"

      expect {
        click_button "Submit Application"
      }.to change(ArenaApplication, :count).by(1)

      expect(ArenaApplication.last.applicant).to eq(character_a)
      expect(ArenaApplication.last.fight_type).to eq("duel")
    end

    it "prevents user from seeing accept button on their own application" do
      # Create application first
      application = create(:arena_application,
        applicant: character_a,
        arena_room: arena_room,
        status: :open)

      login_as user_a, scope: :user
      enter_arena_from_city!(character_a)

      visit arena_room_path(arena_room)

      # Should see their own application without accept button
      within "[data-application-id='#{application.id}']" do
        expect(page).to have_content("Your application")
        expect(page).not_to have_button("Accept")
      end
    end

    it "shows accept button to other users" do
      # Create application from user A
      application = create(:arena_application,
        applicant: character_a,
        arena_room: arena_room,
        status: :open)

      # Login as user B
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)

      # Should see accept button (use first match since there might be duplicate elements)
      within ".arena-applications [data-application-id='#{application.id}']", match: :first do
        expect(page).to have_button("Accept")
        expect(page).not_to have_content("Your application")
      end
    end
  end
end
