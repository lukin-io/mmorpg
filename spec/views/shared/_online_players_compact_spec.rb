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

    expect(rendered).to have_css(".nl-player-menu", visible: :all)
    expect(rendered).to include("Private Message")
    expect(rendered).to include("View Info")
    expect(rendered).to include("Invite")
    expect(rendered).to include("Ignore")
  end

  # These tests require UserSession model/factory which doesn't exist
  # The online_players_compact partial queries user_sessions table
  context "with online users", skip: "UserSession model not implemented" do
    it "displays online players"
    it "shows player name as link"
    it "shows player level in brackets"
    it "shows activity status indicator"
    it "includes click actions for whisper and context menu"
  end

  context "with no online users", skip: "UserSession model not implemented" do
    it "shows empty message"
  end

  context "context menu buttons" do
    # The context menu is hidden by default, so we need visible: :all
    it "has whisper button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#whisperPlayer']", visible: :all)
    end

    it "has view profile button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#viewProfile']", visible: :all)
    end

    it "has copy nickname button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#copyNickname']", visible: :all)
    end

    it "has invite to party button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#inviteToParty']", visible: :all)
    end

    it "has ignore player button" do
      render partial: "shared/online_players_compact"

      expect(rendered).to have_css("button[data-action='click->game-layout#ignorePlayer']", visible: :all)
    end
  end
end
