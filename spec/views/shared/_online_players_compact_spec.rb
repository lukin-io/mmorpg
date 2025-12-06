# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_online_players_compact.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Test City") }
  let(:position) { create(:character_position, zone: zone) }

  before do
    assign(:position, position)
    assign(:zone, zone)

    without_partial_double_verification do
      allow(view).to receive(:profile_path).and_return("/profile/test")
    end
  end

  it "renders the players sidebar" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-players-sort-bar")
    expect(rendered).to have_css(".nl-players-header")
    expect(rendered).to have_css(".nl-players-list")
  end

  it "renders sorting options" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-players-sort")
    expect(rendered).to have_link("a-z")
    expect(rendered).to have_link("z-a")
    expect(rendered).to have_link("0-33")
    expect(rendered).to have_link("33-0")
  end

  it "renders refresh toggle checkbox" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-refresh-toggle")
    expect(rendered).to have_css("input[type='checkbox']")
  end

  it "displays location name in header" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-players-location")
    expect(rendered).to include("Test City")
  end

  it "displays total player count" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-players-total")
  end

  it "renders the player context menu" do
    render partial: "shared/online_players_compact"

    expect(rendered).to have_css(".nl-player-menu")
    expect(rendered).to include("Private Message")
    expect(rendered).to include("View Info")
    expect(rendered).to include("Invite")
    expect(rendered).to include("Ignore")
  end

  context "with online users" do
    let!(:online_user) do
      user = create(:user, profile_name: "TestPlayer")
      character = create(:character, user: user, name: "TestHero", level: 15)
      session = create(:user_session, user: user, last_seen_at: 1.minute.ago)
      user
    end

    it "displays online players" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css(".nl-player-entry")
    end

    it "shows player name as link" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css(".nl-player-name-link")
    end

    it "shows player level in brackets" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css(".nl-player-level")
    end

    it "shows activity status indicator" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css(".nl-player-status-icon")
    end

    it "includes click actions for whisper and context menu" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("[data-action*='click->game-layout#whisperPlayer']")
      expect(rendered).to have_css("[data-action*='contextmenu->game-layout#showPlayerMenu']")
    end
  end

  context "with no online users" do
    before do
      # Ensure no users have active sessions
      UserSession.update_all(last_seen_at: 10.minutes.ago)
    end

    it "shows empty message" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css(".nl-players-empty")
    end
  end

  context "context menu buttons" do
    it "has whisper button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#whisperPlayer']")
    end

    it "has view profile button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#viewProfile']")
    end

    it "has copy nickname button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#copyNickname']")
    end

    it "has invite to party button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#inviteToParty']")
    end

    it "has ignore player button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#ignorePlayer']")
    end
  end
end

