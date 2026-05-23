# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Map Navigation", type: :system do
  include Warden::Test::Helpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 50, height: 50) }
  let(:character) { create(:character, user: user, name: "max_kerby_world", level: 5) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 25, y: 25) }

  def create_explicit_tiles(zone, x_range:, y_range:, terrain_type: zone.location_type)
    x_range.each do |x|
      y_range.each do |y|
        MapTileTemplate.find_or_create_by!(zone: zone.name, x:, y:) do |tile|
          tile.terrain_type = terrain_type
          tile.passable = true
          tile.metadata = {}
        end
      end
    end
  end

  before do
    driven_by(:rack_test)
    login_as(user, scope: :user)
    create_explicit_tiles(zone, x_range: 23..27, y_range: 23..27)
  end

  describe "viewing the world map" do
    it "displays the map container" do
      visit world_path

      expect(page).to have_css(".nl-map-container")
    end

    it "displays the current zone name" do
      visit world_path

      expect(page).to have_content("Окрестность Форпоста")
    end

    it "displays the current coordinates" do
      visit world_path

      expect(page).to have_content("25")
    end

    it "displays the outdoor location context" do
      visit world_path

      expect(page).to have_content("На этой местности возможны нападения ботов.")
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

    it "renders outdoor tile classes" do
      visit world_path

      expect(page).to have_css(".nl-tile-bg--outdoor")
    end
  end

  describe "city view" do
    let(:city_zone) do
      create(:zone,
        name: "Форпост",
        location_type: "city",
        width: 15,
        height: 15,
        metadata: {"description" => "Форпост"})
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

      expect(page).to have_content("Форпост")
    end
  end

  describe "navigation" do
    it "shows navigation links" do
      visit world_path

      expect(page).to have_link("Персонаж")
    end

    it "shows zone name" do
      visit world_path

      expect(page).to have_content("Окрестность Форпоста")
    end

    it "shows location info" do
      visit world_path

      expect(page).to have_css(".location-info-panel")
      expect(page).to have_content("Местность")
    end

    it "does not show duplicate generic movement actions" do
      visit world_path

      expect(page).not_to have_content("Actions")
      expect(page).not_to have_css(".direction-btn")
    end
  end

  describe "map controls" do
    it "displays movement form" do
      visit world_path

      expect(page).to have_css("#movement-form", visible: :all)
    end

    it "offers movement through clickable map tiles" do
      visit world_path

      expect(page).to have_css(".nl-tile-clickable--available")
    end
  end
end
