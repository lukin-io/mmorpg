# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_map.html.erb", type: :view do
  let(:zone) { create(:zone, name: "Test Zone", biome: "forest", width: 20, height: 20) }
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

  let(:nearby_tiles) do
    # Generate a 5x5 grid of tiles
    (8..12).map do |y|
      (8..12).map do |x|
        OpenStruct.new(
          x: x,
          y: y,
          terrain_type: "forest",
          walkable: true,
          metadata: {}
        )
      end
    end
  end

  before do
    assign(:position, position)
    assign(:zone, zone)
    assign(:movement_cooldown, 3)

    # Stub helper methods
    without_partial_double_verification do
      allow(view).to receive(:move_world_path).and_return("/world/move")
    end
  end

  describe "map container" do
    it "renders the map container with stimulus controller" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-map-container[data-controller='nl-world-map']")
    end

    # Regression test: Map container must not include turbo-frame
    # The turbo-frame wrapper is in show.html.erb, not the partial
    # This allows turbo_stream.update to work correctly
    it "does not include turbo-frame wrapper (wrapper is in parent template)" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).not_to have_css("turbo-frame")
    end

    it "includes player position data attributes" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-player-x-value='10']")
      expect(rendered).to have_css("[data-nl-world-map-player-y-value='10']")
    end

    it "includes move URL data attribute" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-move-url-value='/world/move']")
    end

    it "includes zone dimensions data attributes" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-zone-width-value='20']")
      expect(rendered).to have_css("[data-nl-world-map-zone-height-value='20']")
    end

    it "includes movement cooldown data attribute" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-move-cooldown-value='3']")
    end
  end

  describe "map viewport" do
    it "renders the map viewport" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-map-viewport")
    end

    it "renders the map world container" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-map-world")
    end
  end

  describe "tile rendering" do
    it "renders tiles with correct data attributes" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("td[data-x='10'][data-y='10']")
    end

    it "renders tile IDs in correct format" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("td#tile_10_10")
    end

    it "renders terrain class based on terrain type" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-tile-bg--forest")
    end
  end

  describe "clickable tiles (mouse navigation)" do
    it "marks adjacent walkable tiles as clickable with data-available" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      # Adjacent tiles (9,10), (11,10), (10,9), (10,11) should be marked available
      expect(rendered).to have_css(".nl-tile-clickable[data-available='true']", minimum: 4)
    end

    it "includes click action binding for available tiles" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-action='click->nl-world-map#clickTile']", minimum: 4)
    end

    it "sets cursor pointer style on clickable tiles" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to include("cursor: pointer")
    end

    it "does not mark player position as clickable" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      # The player's tile (10,10) should have nl-tile-player, not nl-tile-clickable--available
      expect(rendered).to have_css("td#tile_10_10 .nl-tile-player")
      expect(rendered).not_to have_css("td#tile_10_10 .nl-tile-clickable--available")
    end

    it "does not mark non-adjacent tiles as clickable" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      # Tile (8,8) is diagonal, not adjacent - should not be clickable
      expect(rendered).to have_css("td#tile_8_8 .nl-tile-inactive")
    end
  end

  describe "cursor overlay" do
    it "includes the cursor element" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-cursor")
    end

    it "includes cursor image with idle class" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-cursor-img.nl-cursor-img--idle")
    end

    it "includes stimulus targets for cursor" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-target='cursor']")
      expect(rendered).to have_css("[data-nl-world-map-target='cursorImg']")
    end
  end

  describe "timer overlay" do
    it "includes the timer text element" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-timer-text", visible: :all)
    end

    it "includes timer seconds span" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-timer-seconds", visible: :all)
    end

    it "timer is hidden by default" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to include("display: none")
    end

    it "includes stimulus targets for timer" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-target='timerDiv']", visible: :all)
      expect(rendered).to have_css("[data-nl-world-map-target='timerSeconds']", visible: :all)
    end
  end

  describe "location info bar" do
    it "includes location info bar" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-map-info")
    end

    it "displays zone name" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to include("Test Zone")
    end

    it "displays player coordinates" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to include("[10, 10]")
    end
  end

  describe "hidden movement form" do
    # Critical: The map must include a hidden form for Turbo to handle movement submissions
    it "includes a hidden movement form" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("form#movement-form", visible: :all)
    end

    it "movement form has direction input" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("form#movement-form input#movement-direction", visible: :all)
    end

    it "movement form has data-turbo attribute" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("form#movement-form[data-turbo='true']", visible: :all)
    end

    it "movement form is a stimulus target" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("form[data-nl-world-map-target='moveForm']", visible: :all)
    end
  end

  describe "entity markers on tiles" do
    context "with NPC on a tile" do
      let(:nearby_tiles_with_npc) do
        tiles = nearby_tiles
        tiles[1][1] = OpenStruct.new(
          x: 9,
          y: 9,
          terrain_type: "forest",
          walkable: true,
          metadata: {"npc" => "Goblin Scout"}
        )
        tiles
      end

      it "renders NPC marker" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_npc,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to have_css(".nl-tile-npc")
      end

      it "includes NPC name in title" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_npc,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to include("Goblin Scout")
      end
    end

    context "with resource on a tile" do
      let(:nearby_tiles_with_resource) do
        tiles = nearby_tiles
        tiles[2][2] = OpenStruct.new(
          x: 10,
          y: 10,
          terrain_type: "forest",
          walkable: true,
          metadata: {"resource" => "Oak Wood", "resource_type" => "wood"}
        )
        tiles
      end

      it "renders resource marker" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_resource,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to have_css(".nl-tile-resource")
      end

      it "displays wood icon for wood resource" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_resource,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to include("🪵")
      end
    end

    context "with herb resource" do
      let(:nearby_tiles_with_herb) do
        tiles = nearby_tiles
        tiles[2][2] = OpenStruct.new(
          x: 10,
          y: 10,
          terrain_type: "forest",
          walkable: true,
          metadata: {"resource" => "Moonleaf", "resource_type" => "herb"}
        )
        tiles
      end

      it "displays herb icon" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_herb,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to include("🌿")
      end
    end

    context "with ore resource" do
      let(:nearby_tiles_with_ore) do
        tiles = nearby_tiles
        tiles[2][2] = OpenStruct.new(
          x: 10,
          y: 10,
          terrain_type: "mountain",
          walkable: true,
          metadata: {"resource" => "Iron Ore", "resource_type" => "ore"}
        )
        tiles
      end

      it "displays ore icon" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_ore,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).to include("⛏️")
      end
    end
  end

  describe "terrain types" do
    let(:mixed_terrain_tiles) do
      [
        [
          OpenStruct.new(x: 8, y: 8, terrain_type: "plains", walkable: true, metadata: {}),
          OpenStruct.new(x: 9, y: 8, terrain_type: "forest", walkable: true, metadata: {}),
          OpenStruct.new(x: 10, y: 8, terrain_type: "mountain", walkable: false, metadata: {})
        ],
        [
          OpenStruct.new(x: 8, y: 9, terrain_type: "river", walkable: false, metadata: {}),
          OpenStruct.new(x: 9, y: 9, terrain_type: "city", walkable: true, metadata: {}),
          OpenStruct.new(x: 10, y: 9, terrain_type: "desert", walkable: true, metadata: {})
        ]
      ]
    end

    it "renders different terrain classes" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: mixed_terrain_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-tile-bg--plains")
      expect(rendered).to have_css(".nl-tile-bg--forest")
      expect(rendered).to have_css(".nl-tile-bg--mountain")
      expect(rendered).to have_css(".nl-tile-bg--river")
      expect(rendered).to have_css(".nl-tile-bg--city")
      expect(rendered).to have_css(".nl-tile-bg--desert")
    end
  end

  describe "unwalkable tiles" do
    let(:tiles_with_blocked) do
      (8..12).map do |y|
        (8..12).map do |x|
          walkable = !(x == 9 && y == 10) # Block tile to the west of player
          OpenStruct.new(
            x: x,
            y: y,
            terrain_type: walkable ? "forest" : "mountain",
            walkable: walkable,
            metadata: walkable ? {} : {"blocked" => true}
          )
        end
      end
    end

    it "does not mark unwalkable adjacent tiles as clickable" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: tiles_with_blocked,
        zone: zone,
        tile_data: {}
      }

      # Tile (9, 10) is adjacent but unwalkable - should not be clickable
      expect(rendered).not_to have_css("td#tile_9_10 .nl-tile-clickable--available")
    end
  end
end
