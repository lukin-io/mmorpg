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

      expect(page).to have_css(".nl-timer-text", visible: :all)
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

  describe "navigation" do
    it "shows navigation links" do
      visit world_path

      expect(page).to have_link("Quests")
      expect(page).to have_link("Profile")
    end

    it "shows zone name" do
      visit world_path

      expect(page).to have_content("Adventure Plains")
    end

    it "shows location info" do
      visit world_path

      expect(page).to have_css(".location-info-panel").or have_content("Current Location")
    end

    it "shows available actions" do
      visit world_path

      expect(page).to have_css(".actions-panel").or have_content("Actions")
    end
  end

  describe "map controls" do
    it "displays movement form" do
      visit world_path

      expect(page).to have_css("#movement-form", visible: :all)
    end

    it "displays movement buttons" do
      visit world_path

      expect(page).to have_button("↑ North").or have_css(".direction-btn")
    end
  end
end
