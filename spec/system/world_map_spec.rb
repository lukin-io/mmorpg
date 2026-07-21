# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World Map Navigation", type: :system do
  include Warden::Test::Helpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 50, height: 50) }
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
      expect(page).to have_css("body.nl-game-layout")
    end

    it "displays the current zone name" do
      visit world_path

      expect(page).to have_content("Outpost Surroundings")
    end

    it "displays the current coordinates" do
      visit world_path

      expect(page).to have_content("25")
    end

    it "displays the outdoor location context" do
      visit world_path

      within("#location-info") do
        expect(page).to have_content("Outpost Surroundings [25, 25]")
        expect(page).not_to have_content("Hostile NPCs may attack")
      end
    end

    it "shows the map viewport" do
      visit world_path

      expect(page).to have_css(".nl-map-viewport")
      expect(page).to have_css(".nl-map-tile", count: 49)
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

    it "renders source-backed cell art without revealing a cell NPC" do
      tile = MapTileTemplate.find_by!(zone: zone.name, x: 24, y: 25)
      tile.update!(
        metadata: {
          "source_map" => "m_1001_999",
          "cell_art" => {"key" => "forpost_terrain", "column" => 7, "row" => 7}
        }
      )
      npc_template = create(:npc_template, name: "Hidden System Rat", npc_key: "hidden_system_rat")
      create(:tile_npc, zone: zone.name, x: 24, y: 25, npc_template:, npc_key: "hidden_system_rat")

      visit world_path

      expect(page).to have_css("#tile_24_25[data-cell-art-key='forpost_terrain']")
      expect(page).not_to have_css(".nl-tile-npc")
      expect(page).not_to have_content("Hidden System Rat")
    end
  end

  describe "city view" do
    let(:city_zone) do
      create(:zone,
        name: "Outpost",
        location_type: "city",
        width: 15,
        height: 15,
        metadata: {"description" => "Outpost"})
    end

    before do
      position.update!(zone: city_zone, x: 7, y: 7)
    end

    it "displays city view for city zones" do
      visit world_path

      expect(page).to have_css(".city-view-container")
      expect(page).to have_css(".nl-city-scene img.nl-city-scene-image")
    end

    it "shows city description" do
      visit world_path

      expect(page).to have_content("Outpost")
    end
  end

  describe "navigation" do
    it "shows navigation links" do
      visit world_path

      expect(page).to have_button("Character")
    end

    it "shows zone name" do
      visit world_path

      expect(page).to have_content("Outpost Surroundings")
    end

    it "shows location info" do
      visit world_path

      expect(page).to have_css(".location-info-panel")
      expect(page).to have_content("Location")
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


    it "keeps a fixed center cursor and non-clickable buffer at a region boundary" do
      position.update!(x: 0, y: 0)

      visit world_path

      expect(page).to have_css(".nl-map-tile", count: 49)
      expect(page).to have_css(".nl-map-tile--outside")
      expect(page).to have_css(".nl-cursor[style*='left: 200px'][style*='top: 200px']")
    end
  end
end
