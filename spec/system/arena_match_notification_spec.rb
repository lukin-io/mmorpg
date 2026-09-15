# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena match transition and reconciliation", type: :system do
  let(:user_a) { create(:user, email: "user_a@test.com", password: "password123") }
  let(:user_b) { create(:user, email: "user_b@test.com", password: "password123") }
  let!(:character_a) { create(:character, user: user_a, name: "Fighter A", level: 15, current_hp: 100, max_hp: 100) }
  let!(:character_b) { create(:character, user: user_b, name: "Fighter B", level: 15, current_hp: 100, max_hp: 100) }
  let!(:arena_room) { create(:arena_room, name: "Test Arena", level_min: 10, level_max: 25, max_concurrent_matches: 5, active: true) }
  before do
    create(:character_position, character: character_a)
    create(:character_position, character: character_b)
  end

  def enter_arena_from_city!(character)
    zone = character.position.zone
    zone.update!(location_type: "city")
    hotspot = create(:city_hotspot, :arena, zone:, active: true, required_level: 1)

    visit world_path
    if character.waiting_arena_application
      expect(page).to have_current_path(arena_room_path(character.waiting_arena_application.arena_room, ft: 1))
    else
      within(".city-actions") { click_button hotspot.name }
      expect(page).to have_current_path(arena_index_path)
    end
  end

  # ===========================================================================
  # Match creation persists for both participants. The room-scoped live update
  # opens the reserved Duel only for participants currently viewing that room;
  # other Arena pages reconcile from the authoritative match on navigation.
  # ===========================================================================

  describe "match creation for both participants" do
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

      it "restores the reserved room and reconciles the persisted match" do
        login_as user_a, scope: :user
        enter_arena_from_city!(character_a)
        visit arena_index_path

        result = Arena::ApplicationHandler.new.accept(
          application:,
          acceptor: character_b
        )

        expect(result.success?).to be(true)
        expect(page).to have_current_path(arena_room_path(arena_room, ft: 1))

        visit arena_index_path

        expect(page).to have_current_path(arena_match_path(result.match))
        expect(page).to have_content("You already have an active fight.")
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
      create(:arena_match, arena_room: arena_room, status: :live)
    end

    before do
      create(:arena_participation, arena_match: arena_match, character: character_a, user: user_a, team: "a")
      create(:arena_participation, arena_match: arena_match, character: character_b, user: user_b, team: "b")
    end

    it "redirects user with active match from arena index to match page" do
      login_as user_a, scope: :user

      visit arena_index_path

      expect(page).to have_current_path(arena_match_path(arena_match))
      expect(page).to have_content("You already have an active fight.")
    end

    it "redirects user with active match from room page to match page" do
      login_as user_a, scope: :user

      visit arena_room_path(arena_room)

      expect(page).to have_current_path(arena_match_path(arena_match))
      expect(page).to have_content("You already have an active fight.")
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
      expect(page).not_to have_content("You already have an active fight.")
    end
  end

  # ===========================================================================
  # UI: Countdown display
  # ===========================================================================

  describe "Duel confirmation", js: true do
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

    it "allows refusal and reacceptance before the applicant starts" do
      login_as user_b, scope: :user
      enter_arena_from_city!(character_b)

      visit arena_room_path(arena_room)
      click_button "Accept"

      expect(page).to have_content("Waiting for the fight to begin!")
      expect(page).not_to have_button("Start Duel")
      click_button "Refuse Duel"
      expect(page).to have_current_path(arena_room_path(arena_room))
      click_button "Accept"
      expect(page).to have_button("Refuse Duel")
      match = application.reload.arena_match
      using_session(:applicant_confirmation) do
        # A background poll in the other session can consume Warden's global
        # next-request login hook. Authenticate this browser through its form.
        visit new_user_session_path
        fill_in "Email", with: user_a.email
        fill_in "Password", with: "password123"
        click_button "Enter"
        expect(page).to have_current_path(arena_match_path(match))
        visit arena_match_path(match)
        click_button "Start Duel"
        expect(page).to have_css(".arena-action-panel")
        expect(match.reload).to be_live
        within(".nl-top-bar") { click_link "Fighter A" }
        expect(page).to have_current_path(player_path(name: character_a.name))
        expect(page).not_to have_css("body[data-game-layout-encounter-url-value]")
        click_link "in combat"
        expect(page).to have_current_path(public_fight_log_path(match))
      end
      expect(page).to have_css(".arena-action-panel", wait: 8)
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
        expect(page).to have_button("Cancel Application")
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
  it "posts a Group form, joins the selected side and releases a withdrawn place", js: true do
    login_as user_a, scope: :user
    enter_arena_from_city!(character_a)
    visit arena_room_path(arena_room, ft: 2)
    select "Free", from: "fight_kind"
    select "4 min", from: "timeout_seconds"
    select "high (50%)", from: "trauma_percent"
    select "5 min", from: "wait_minutes"
    expect(page).to have_field("team_count", with: "")
    {"team_count" => 2, "enemy_count" => 2,
     "team_level_min" => 10, "team_level_max" => 25,
     "enemy_level_min" => 10, "enemy_level_max" => 25}.each do |field, value|
      fill_in field, with: value
    end
    click_button "Submit Application"
    expect(page).to have_content("Waiting for the fight to begin!")
    application = ArenaApplication.find_by!(applicant: character_a, status: :open)
    expect(application).to have_attributes(team_count: 2, enemy_count: 2, timeout_seconds: 240, trauma_percent: 50)

    click_button "Show building scheme"
    expect(page).to have_css("[data-arena-target='roomGrid']", visible: true)
    # Recovery polling must not discard scheme/focus while the offer is waiting.
    sleep 6
    expect(page).to have_css("[data-arena-target='roomGrid']", visible: true)

    Capybara.using_session(:group_opponent) do
      # Use this browser's login form: Warden's global next-request callback
      # can otherwise be consumed by the applicant's background refresh.
      visit new_user_session_path
      fill_in "Email", with: user_b.email
      fill_in "Password", with: "password123"
      click_button "Enter"
      expect(page).to have_current_path(world_path)
      enter_arena_from_city!(character_b)
      visit arena_room_path(arena_room, ft: 2)
      choose "application_#{application.id}_b"
      click_button "Accept"
      expect(page).to have_button("Leave Group")
      expect(application.reload.members_for("b").map(&:character_id)).to eq([character_b.id])
      click_button "Leave Group"
      expect(page).to have_button("Submit Application")
      expect(character_b.waiting_arena_application).to be_nil
    end
    click_button "Cancel Application"
    expect(page).to have_button("Submit Application")
    expect(application.reload).to be_cancelled
  end

  it "opens a recent fight log outside the game frame and follows its statistics", js: true do
    match = create(:arena_match, :completed, arena_room:)
    create(:arena_participation, :defeat, arena_match: match, character: character_a, user: user_a)
    login_as user_a, scope: :user
    enter_arena_from_city!(character_a)

    within(".nl-arena-recent") { click_link "log" }
    expect(page).to have_current_path(public_fight_log_path(match))
    expect(page).not_to have_content("Content missing")
    click_link "Statistics"
    expect(page).to have_current_path(public_fight_log_path(match, stat: 1))
    expect(page).to have_content(character_a.name)
  end
end
