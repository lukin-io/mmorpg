# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Map Navigation", type: :system do
  include Warden::Test::Helpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Adventure Plains", biome: "plains", width: 50, height: 50) }
  let(:character) { create(:character, user: user, name: "TestHero", level: 5) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 25, y: 25) }

  before do
    driven_by(:rack_test)
    login_as(user, scope: :user)
  end

  describe "viewing the world map" do
    it "displays the map container" do
      visit world_path

      expect(page).to have_css(".nl-map-container")
    end

    it "displays the current zone name" do
      visit world_path

      expect(page).to have_content("Adventure Plains")
    end

    it "displays the current coordinates" do
      visit world_path

      expect(page).to have_content("25")
    end

    it "displays the biome type" do
      visit world_path

      expect(page).to have_content("Plains")
    end

    it "shows the map viewport" do
      visit world_path

      expect(page).to have_css(".nl-map-viewport")
    end

    it "shows the cursor element" do
      visit world_path

      expect(page).to have_css(".nl-cursor")
    end

    it "shows the timer elements (hidden by default)" do
      visit world_path

      expect(page).to have_css(".nl-timer-bg", visible: :hidden)
      expect(page).to have_css(".nl-timer-text", visible: :hidden)
    end
  end

  describe "map tile rendering" do
    it "renders tiles with data attributes" do
      visit world_path

      expect(page).to have_css("[data-x]")
      expect(page).to have_css("[data-y]")
    end

    it "renders terrain-based tile classes" do
      visit world_path

      expect(page).to have_css(".nl-tile-bg--plains")
    end
  end

  describe "city view" do
    let(:city_zone) do
      create(:zone,
        name: "Capital City",
        biome: "city",
        width: 15,
        height: 15,
        metadata: {"description" => "The grand capital of the realm."})
    end

    before do
      position.update!(zone: city_zone, x: 7, y: 7)
    end

    it "displays city view for city zones" do
      visit world_path

      expect(page).to have_css(".nl-city-view").or have_css(".city-view")
    end

    it "shows city description" do
      visit world_path

      expect(page).to have_content("grand capital")
    end
  end

  describe "status bar" do
    it "shows character name" do
      visit world_path

      expect(page).to have_content("TestHero")
    end

    it "shows character level" do
      visit world_path

      expect(page).to have_content("[5]")
    end

    it "shows vitals bar" do
      visit world_path

      expect(page).to have_css(".nl-vitals")
    end

    it "shows action buttons" do
      visit world_path

      expect(page).to have_css(".nl-action-buttons")
      expect(page).to have_link("Quests")
      expect(page).to have_link("Character")
      expect(page).to have_link("Inventory")
    end
  end

  describe "bottom panel" do
    it "shows chat tabs" do
      visit world_path

      expect(page).to have_css(".nl-chat-tabs")
      expect(page).to have_button("Chat")
      expect(page).to have_button("Battle")
      expect(page).to have_button("Events")
      expect(page).to have_button("System")
    end

    it "shows chat input field" do
      visit world_path

      expect(page).to have_css(".nl-chat-field")
    end

    it "shows online players section" do
      visit world_path

      expect(page).to have_css(".nl-players-section")
    end
  end

  describe "keyboard navigation hints" do
    it "displays control hints" do
      visit world_path

      expect(page).to have_css(".nl-map-controls").or have_css(".nl-control-hint")
    end
  end
end
