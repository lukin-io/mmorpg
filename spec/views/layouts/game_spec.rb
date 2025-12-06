# frozen_string_literal: true

require "rails_helper"

RSpec.describe "layouts/game.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, name: "TestHero", level: 10) }
  let(:zone) { create(:zone, name: "Test Zone", biome: "plains") }
  let(:position) { create(:character_position, character: character, zone: zone) }
  let(:chat_channel) { create(:chat_channel, name: "Global", channel_type: :global) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_character).and_return(character)
    allow(view).to receive(:user_signed_in?).and_return(true)
    assign(:position, position)
    assign(:chat_channel, chat_channel)
    assign(:players_here, [])

    # Stub character methods
    allow(character).to receive(:current_hp).and_return(80)
    allow(character).to receive(:max_hp).and_return(100)
    allow(character).to receive(:current_mp).and_return(40)
    allow(character).to receive(:max_mp).and_return(50)
    allow(character).to receive(:gold).and_return(1500)
    allow(character).to receive(:hp_regen_interval_seconds).and_return(1500)
    allow(character).to receive(:mp_regen_interval_seconds).and_return(9000)

    # Stub ChatChannel.global
    allow(ChatChannel).to receive(:global).and_return(ChatChannel.where(id: chat_channel.id))
  end

  describe "layout structure" do
    it "renders the game layout body class" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css("body.nl-game-layout")
    end

    it "includes game-layout stimulus controller" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css("[data-controller='game-layout']")
    end
  end

  describe "top bar" do
    it "renders the top bar" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-top-bar")
    end

    it "displays character name as link" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-player-link")
      expect(rendered).to include("TestHero")
    end

    it "displays character level in brackets" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-player-level")
      expect(rendered).to include("[10]")
    end

    it "renders the inline vitals bar" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-vitals-inline")
    end

    it "shows exit/close button" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-close-btn")
    end
  end

  describe "navigation links (right side of top bar)" do
    it "renders navigation container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-top-nav")
    end

    it "includes Quests link" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_link("Quests", class: "nl-nav-link")
    end

    it "includes Character link" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_link("Character", class: "nl-nav-link")
    end

    it "includes Inventory link" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_link("Inventory", class: "nl-nav-link")
    end

    it "includes Enter/Exit link" do
      render template: "layouts/game", layout: false

      # Either "Enter" (for outdoor) or "Exit" (for city)
      expect(rendered).to have_css(".nl-nav-link", minimum: 4)
    end
  end

  describe "main content area" do
    it "renders main content container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-main-area")
    end

    it "includes turbo frame for main content" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css("turbo-frame#main_content")
    end
  end

  describe "floating players panel" do
    it "renders floating players panel" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-players-float")
    end

    it "includes sort links" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-sort-links")
    end

    it "includes refresh checkbox" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-refresh-check input[type='checkbox']")
    end

    it "shows location info" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-players-location")
    end

    it "includes players list container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-players-list-float")
    end
  end

  describe "bottom chat bar" do
    it "renders bottom bar" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-bottom-bar")
    end

    it "includes action buttons" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-action-area")
      expect(rendered).to have_css(".nl-action-btn-small", minimum: 2)
    end

    it "includes chat area" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-chat-area")
    end

    it "includes chat messages container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-chat-messages")
    end

    it "includes chat input field" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-chat-input-field")
    end

    it "includes time display" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-time-display")
    end
  end

  describe "flash messages" do
    it "renders flash container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-flash-container")
    end
  end

  describe "notifications" do
    it "renders notifications container" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_css(".nl-notifications")
    end
  end

  describe "when in city zone" do
    let(:city_zone) { create(:zone, name: "City", biome: "city") }
    let(:city_position) { create(:character_position, character: character, zone: city_zone) }

    before do
      assign(:position, city_position)
    end

    it "shows Exit link instead of Enter" do
      render template: "layouts/game", layout: false

      expect(rendered).to have_link("Exit", class: "nl-nav-link")
    end
  end

  describe "when not signed in" do
    before do
      allow(view).to receive(:user_signed_in?).and_return(false)
      allow(view).to receive(:current_character).and_return(nil)
    end

    it "does not show navigation links" do
      render template: "layouts/game", layout: false

      expect(rendered).not_to have_css(".nl-nav-link")
    end

    it "does not show close button" do
      render template: "layouts/game", layout: false

      expect(rendered).not_to have_css(".nl-close-btn")
    end
  end
end
