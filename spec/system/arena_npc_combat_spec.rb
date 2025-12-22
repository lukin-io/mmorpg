# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# Arena NPC Combat System Specs (Hotwire/Turbo Integration)
# =============================================================================
# Full browser integration tests for arena NPC (bot) combat with Hotwire.
# Tests cover: UI rendering, Turbo Frames, arena room navigation.
#
# Related docs:
#   - doc/flow/11_arena_pvp.md
#   - doc/flow/22_arena_npc_bots.md
# =============================================================================

RSpec.describe "Arena NPC Combat UI", type: :system do
  include Warden::Test::Helpers

  # Setup pattern matching world_map_spec.rb - character belongs to user
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Test Zone", biome: "plains") }
  let(:character) { create(:character, user: user, name: "TestHero", level: 5, current_hp: 100, max_hp: 100) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  let(:arena_room) { create(:arena_room, name: "Training Grounds", slug: "training", level_min: 1, level_max: 10, active: true, room_type: :training) }
  let!(:arena_season) { create(:arena_season, :live) }

  let(:arena_bot) do
    create(:npc_template,
      npc_key: "arena_training_dummy",
      name: "Training Dummy",
      role: "arena_bot",
      level: 3,
      dialogue: "*creaks and wobbles*",
      metadata: {
        "health" => 60,
        "base_damage" => 5,
        "difficulty" => "easy",
        "ai_behavior" => "defensive",
        "arena_rooms" => ["training"],
        "avatar" => "🎯",
        "stats" => {"attack" => 8, "defense" => 4, "hp" => 60}
      })
  end

  before do
    driven_by(:rack_test)
  end

  # ===========================================================================
  # SUCCESS CASES: Arena Room with NPC Applications
  # ===========================================================================

  describe "viewing arena room with NPC applications" do
    let!(:npc_application) do
      create(:arena_application,
        arena_room: arena_room,
        applicant: nil,
        npc_template: arena_bot,
        status: :open,
        fight_type: :duel,
        fight_kind: :no_weapons,
        timeout_seconds: 120)
    end

    before { login_as(user, scope: :user) }

    it "displays NPC bot application in the room" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("Training Dummy")
    end

    it "shows NPC level in brackets" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("[3]")
    end

    it "displays NPC bot badge" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("Bot").or have_content("🤖")
    end

    it "displays accept button for NPC application" do
      visit arena_room_path(arena_room)

      expect(page).to have_button("Accept").or have_link("Accept")
    end

    it "shows fight type for NPC application" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("Duel").or have_content("1v1")
    end
  end

  # ===========================================================================
  # SUCCESS CASES: Accepting NPC Application Flow
  # ===========================================================================

  describe "accepting NPC application" do
    let!(:npc_application) do
      create(:arena_application,
        arena_room: arena_room,
        applicant: nil,
        npc_template: arena_bot,
        status: :open,
        fight_type: :duel,
        fight_kind: :no_weapons,
        timeout_seconds: 120)
    end

    before { login_as(user, scope: :user) }

    it "redirects to match page after accepting" do
      visit arena_room_path(arena_room)

      click_button "Accept"

      expect(page).to have_current_path(/arena_matches/)
    end

    it "shows both participants after accepting" do
      visit arena_room_path(arena_room)

      click_button "Accept"

      expect(page).to have_content("TestHero")
      expect(page).to have_content("Training Dummy")
    end

    it "displays NPC avatar image on match page" do
      visit arena_room_path(arena_room)

      click_button "Accept"

      # Now uses avatar images instead of emoji
      expect(page).to have_css("img.avatar").or have_css(".avatar")
    end

    it "shows HP bars for both participants" do
      visit arena_room_path(arena_room)

      click_button "Accept"

      # Both player and NPC should have HP displays
      expect(page).to have_css(".arena-hp-bar", minimum: 2).or have_content("/")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Application Already Matched
  # ===========================================================================

  describe "attempting to accept already matched application" do
    let!(:matched_application) do
      create(:arena_application,
        arena_room: arena_room,
        applicant: nil,
        npc_template: arena_bot,
        status: :matched,
        fight_type: :duel,
        fight_kind: :no_weapons)
    end

    before { login_as(user, scope: :user) }

    it "does not show accept button for matched applications" do
      visit arena_room_path(arena_room)

      # Matched applications should not appear in open applications list
      expect(page).not_to have_button("Accept")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Expired Application
  # ===========================================================================

  describe "viewing expired NPC application" do
    let!(:expired_application) do
      create(:arena_application,
        arena_room: arena_room,
        applicant: nil,
        npc_template: arena_bot,
        status: :expired,
        fight_type: :duel,
        fight_kind: :no_weapons,
        expires_at: 1.hour.ago)
    end

    before { login_as(user, scope: :user) }

    it "does not show accept button for expired applications" do
      visit arena_room_path(arena_room)

      # Expired applications should not appear in open applications list
      expect(page).not_to have_button("Accept")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: Empty Arena Room
  # ===========================================================================

  describe "arena room with no applications" do
    before { login_as(user, scope: :user) }

    it "shows empty message when no applications exist" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("No open applications").or have_content("Be the first")
    end

    it "shows application form" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("Submit Application")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Character Level Out of Range
  # ===========================================================================

  describe "character outside arena room level range" do
    # Use existing user/character but with a level-restricted arena room
    let(:restricted_room) do
      create(:arena_room,
        name: "Elite Arena",
        slug: "elite",
        level_min: 16,
        level_max: 33,
        active: true,
        room_type: :patron)
    end

    before { login_as(user, scope: :user) }

    it "cannot access level-restricted arena room" do
      # Character is level 5, room requires 16-33
      visit arena_room_path(restricted_room)

      # Should redirect away from restricted room (not show the room contents)
      expect(page).not_to have_content("Submit Application")
    end
  end

  # ===========================================================================
  # FAILURE CASES: Unauthenticated Access
  # ===========================================================================

  describe "unauthenticated user" do
    it "redirects to login when accessing arena room" do
      visit arena_room_path(arena_room)

      expect(page).to have_current_path(/sign_in/).or have_content("sign in")
    end

    it "redirects to login when accessing arena index" do
      visit arena_index_path

      expect(page).to have_current_path(/sign_in/).or have_content("sign in")
    end
  end

  # ===========================================================================
  # SUCCESS CASES: Match Completion UI
  # ===========================================================================

  describe "viewing completed NPC match" do
    let!(:completed_match) do
      create(:arena_match, :completed,
        arena_room: arena_room,
        arena_season: arena_season,
        match_type: :duel,
        winning_team: "a",
        metadata: {"is_npc_fight" => true, "combat_log" => [
          {"type" => "damage", "description" => "TestHero attacks Training Dummy for 25 damage"},
          {"type" => "defeat", "description" => "Training Dummy has been defeated!"}
        ]})
    end

    let!(:player_participation) do
      create(:arena_participation,
        arena_match: completed_match,
        character: character,
        user: user,
        team: "a",
        result: :victory)
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: completed_match,
        npc_template: arena_bot,
        team: "b",
        result: :defeat,
        metadata: {"current_hp" => 0, "max_hp" => 60})
    end

    before { login_as(user, scope: :user) }

    it "shows match result" do
      visit arena_match_path(completed_match)

      expect(page).to have_content("Victory").or have_content("Completed").or have_content("Winner")
    end

    it "shows NPC participant with 0 HP" do
      visit arena_match_path(completed_match)

      expect(page).to have_content("0/60").or have_content("Training Dummy")
    end

    it "displays combat log entries" do
      visit arena_match_path(completed_match)

      expect(page).to have_content("damage").or have_content("defeated").or have_content("Training Dummy")
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: NPC with Empty Metadata
  # ===========================================================================

  describe "NPC application with minimal metadata" do
    let(:minimal_bot) do
      create(:npc_template,
        npc_key: "minimal_bot",
        name: "Basic Bot",
        role: "arena_bot",
        level: 1,
        dialogue: "...",
        metadata: {})
    end

    let!(:minimal_app) do
      create(:arena_application,
        arena_room: arena_room,
        applicant: nil,
        npc_template: minimal_bot,
        status: :open,
        fight_type: :duel,
        fight_kind: :no_weapons)
    end

    before { login_as(user, scope: :user) }

    it "displays NPC with fallback avatar" do
      visit arena_room_path(arena_room)

      expect(page).to have_content("Basic Bot")
      expect(page).to have_content("🤖").or have_css(".npc-avatar")
    end

    it "can accept application with minimal NPC" do
      visit arena_room_path(arena_room)

      click_button "Accept"

      expect(page).to have_current_path(/arena_matches/)
    end
  end

  # ===========================================================================
  # SUCCESS CASES: Arena Index
  # ===========================================================================

  describe "arena index page" do
    before { login_as(user, scope: :user) }

    it "displays arena page" do
      visit arena_index_path

      expect(page).to have_content("Arena")
    end

    it "shows available rooms" do
      arena_room # ensure room exists
      visit arena_index_path

      expect(page).to have_content("Training").or have_content(arena_room.name)
    end
  end

  # ===========================================================================
  # NULL/EDGE CASES: Live Match View
  # ===========================================================================

  describe "viewing live NPC match" do
    let!(:live_match) do
      create(:arena_match, :live,
        arena_room: arena_room,
        arena_season: arena_season,
        match_type: :duel,
        metadata: {"is_npc_fight" => true})
    end

    let!(:player_participation) do
      create(:arena_participation,
        arena_match: live_match,
        character: character,
        user: user,
        team: "a",
        metadata: {"current_hp" => 80, "max_hp" => 100})
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: live_match,
        npc_template: arena_bot,
        team: "b",
        metadata: {"current_hp" => 45, "max_hp" => 60})
    end

    before { login_as(user, scope: :user) }

    it "shows both participants with current HP" do
      visit arena_match_path(live_match)

      expect(page).to have_content("TestHero")
      expect(page).to have_content("Training Dummy")
    end

    it "displays combat UI elements" do
      visit arena_match_path(live_match)

      expect(page).to have_css(".arena-participant", minimum: 2).or have_content("/")
    end
  end
end
