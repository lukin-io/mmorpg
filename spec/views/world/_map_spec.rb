# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_map.html.erb", type: :view do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Test Zone", location_type: "outdoor", width: 20, height: 20) }
  let(:character) { create(:character) }
  let(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }
  let(:movement_destinations) do
    [
      OpenStruct.new(direction: "north", target_x: 10, target_y: 9, action_key: "north-key", travel_seconds: 30),
      OpenStruct.new(direction: "south", target_x: 10, target_y: 11, action_key: "south-key", travel_seconds: 30),
      OpenStruct.new(direction: "east", target_x: 11, target_y: 10, action_key: "east-key", travel_seconds: 30),
      OpenStruct.new(direction: "west", target_x: 9, target_y: 10, action_key: "west-key", travel_seconds: 30)
    ]
  end

  let(:nearby_tiles) do
    # Generate the 15x9 source-shaped render buffer around a 13x7 viewport.
    (6..14).map do |y|
      (3..17).map do |x|
        OpenStruct.new(
          x: x,
          y: y,
          terrain_type: "outdoor",
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
    assign(:movement_destinations, movement_destinations)
    assign(:active_movement, nil)
    assign(:movement_remaining_seconds, 0)

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

    it "publishes the one-cell source buffer around the visible stage" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-nl-world-map-map-offset-x-value='-100']")
      expect(rendered).to have_css("[data-nl-world-map-map-offset-y-value='-100']")
      expect(rendered).to have_css("[data-nl-world-map-visible-columns-value='13'][data-nl-world-map-max-visible-columns-value='39']")
      expect(rendered).to have_css("[data-nl-world-map-visible-rows-value='7'][data-nl-world-map-max-visible-rows-value='9']")
      expect(rendered).to have_css(".nl-map-viewport[style*='--nl-map-visible-columns: 13'][style*='--nl-map-visible-rows: 7']")
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
    it "paints the captured western margin while keeping outside cells inactive and farther cells unillustrated" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      position.update!(x: 0, y: 8)
      assign(:movement_destinations, [OpenStruct.new(direction: "west", target_x: -1, target_y: 8,
        action_key: "unavailable-west", travel_seconds: 30)])
      rows = Game::World::MapBuffer.new(position:, columns: 7, rows: 5).call.rows

      render partial: "world/map", locals: {position:, nearby_tiles: rows, zone:, tile_data: {}}

      document = Nokogiri::HTML.fragment(rendered)
      margin = document.css(".nl-map-tile--outside[data-cell-art-key='forpost_starter_west']")
      expect(margin.size).to eq(21)
      margin.each do |cell|
        x, y = [cell["data-x"], cell["data-y"]].map(&:to_i)
        expect(cell["style"]).to include("world/cells/forpost-starter-west/#{x + 3}_#{y - 2}",
          "background-position: 0px 0px", "background-size: 100px 100px")
        expect(cell.css(".nl-tile-inactive").size).to eq(1)
        expect(cell.css("button, [data-action-key]")).to be_empty
      end
      expect(document.at_css("#tile_-4_8")["style"]).to eq("")
      expect(document.at_css("#tile_-4_8")["data-cell-art-key"]).to eq("")
      expect(document.at_css("#tile_0_8")["data-cell-art-key"]).to eq("forpost_starter")
      expect(rendered).not_to include("world/forpost-starter-west-landscape")
      expect(rows.flatten.select { |tile| tile.x.negative? }).to all(have_attributes(walkable: false, passable: false))
    end

    it "renders a continuous eastern-gate neighborhood around sparse content without materializing gameplay cells" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      position.update!(x: 11, y: 9)
      create(:map_tile_template, zone: zone.name, x: 11, y: 9,
        metadata: {"source_map" => "m_1005_1001", "cell_art" => {"key" => "forpost_starter", "column" => 11, "row" => 7}})
      create(:map_tile_template, zone: zone.name, x: 4, y: 6,
        metadata: {"source_map" => "m_998_998", "cell_art" => {"key" => "forpost_terrain", "column" => 4, "row" => 6}})
      rows = Game::World::MapBuffer.new(position:, columns: 13, rows: 7).call.rows
      original_cells = MapTileTemplate.order(:id).map(&:attributes)
      original_position = position.attributes

      render partial: "world/map", locals: {position:, nearby_tiles: rows, zone:, tile_data: {}}

      document = Nokogiri::HTML.fragment(rendered)
      expect(document.css("[data-cell-art-key='forpost_starter']").size).to eq(135)
      rows.flatten.each do |tile|
        style = document.at_css("#tile_#{tile.x}_#{tile.y}")["style"]
        expect(style).to include("world/cells/forpost-starter/#{tile.x}_#{tile.y - 2}", "background-size: 100px 100px")
      end
      expect(rendered).not_to include("world/forpost-terrain")
      expect(rendered).not_to include("world/forpost-starter-landscape")
      expect(MapTileTemplate.order(:id).map(&:attributes)).to eq(original_cells)
      expect(position.reload.attributes).to eq(original_position)
    end

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

      expect(rendered).to have_css(".nl-tile-bg--outdoor")
    end


    it "uses the generic cell CSS without loading a bitmap when artwork is unconfigured" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(Nokogiri::HTML.fragment(rendered).css(".nl-map-tile").map { |cell| cell["style"] }).to all(eq(""))
      expect(rendered).not_to include("world/forpost-terrain")
      expect(rendered).not_to include("neverlands_outskirts")
    end

    it "uses generic cell CSS when a starter PNG is missing, without loading either full atlas" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).and_call_original
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).with("world/cells/forpost-starter/11_7.png").and_return(false)
      tiles = [[OpenStruct.new(x: 11, y: 9, terrain_type: "outdoor", walkable: true, metadata: {})]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      cell = Nokogiri::HTML.fragment(rendered).at_css("#tile_11_9")
      expect(cell["style"]).to eq("")
      expect(cell["class"]).to include("nl-tile-bg--outdoor")
      expect(rendered).not_to include("world/forpost-starter-landscape", "world/forpost-terrain")
    end

    it "offers aligned city images at 1x and 2x while keeping a 100px background" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      tiles = [[OpenStruct.new(x: 6, y: 8, terrain_type: "outdoor", walkable: true, metadata: {})]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      style = Nokogiri::HTML.fragment(rendered).at_css("#tile_6_8")["style"]
      expect(style).to start_with("background-image: url('")
      expect(style).to match(%r{image-set\(url\('[^']*/world/cells/forpost-starter/6_6[^']*'\) 1x, url\('[^']*/world/cells/forpost-starter-2x/6_6[^']*'\) 2x\)})
      expect(style).to include("background-position: 0px 0px", "background-size: 100px 100px")
      expect(style).not_to include("landscape", "200px")
    end

    it "renders only the matching 1x city image when its optional 2x alternative is absent" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).and_call_original
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).with("world/cells/forpost-starter-2x/6_6.png").and_return(false)
      tiles = [[OpenStruct.new(x: 6, y: 8, terrain_type: "outdoor", walkable: true, metadata: {})]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      style = Nokogiri::HTML.fragment(rendered).at_css("#tile_6_8")["style"]
      expect(style).to include("world/cells/forpost-starter/6_6", "background-size: 100px 100px")
      expect(style).not_to include("image-set", "forpost-starter-2x", "landscape")
    end

    it "leaves a missing western slice inert without substituting the master or another cell" do
      zone.update!(name: "Outpost Surroundings", width: 1000, height: 1000, metadata: {"source_map" => "m_1001_999"})
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).and_call_original
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).with("world/cells/forpost-starter-west/2_7.png").and_return(false)
      tiles = [[OpenStruct.new(x: -1, y: 9, terrain_type: "outdoor", walkable: false, metadata: {"out_of_bounds" => true})]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      cell = Nokogiri::HTML.fragment(rendered).at_css("#tile_-1_9")
      expect(cell["style"]).to eq("")
      expect(cell["data-cell-art-key"]).to eq("")
      expect(cell["class"]).to include("nl-map-tile--outside")
      expect(cell.css("button, [data-action-key]")).to be_empty
      expect(rendered).not_to include("world/forpost-starter-west-landscape")
    end

    it "uses a validated source-backed cell-art slice instead of the coordinate fallback" do
      tiles = nearby_tiles
      tiles[3][6] = OpenStruct.new(
        x: 9,
        y: 9,
        terrain_type: "outdoor",
        walkable: true,
        metadata: {
          "source_map" => "m_1001_999",
          "cell_art" => {"key" => "forpost_terrain", "column" => 7, "row" => 7}
        }
      )

      render partial: "world/map", locals: {
        position:,
        nearby_tiles: tiles,
        zone:,
        tile_data: {}
      }

      expect(rendered).to have_css("#tile_9_9[data-cell-art-key='forpost_terrain']")
      expect(rendered).to include("background-position: -700px -700px")
      expect(rendered).to include("background-size: 1000px 1000px")
    end

    it "renders neighboring pond cells as adjacent slices of the same landscape" do
      tiles = nearby_tiles
      tiles.flatten.each do |tile|
        next unless tile.x.between?(11, 15) && tile.y.between?(8, 12)

        tile.metadata = {"source_map" => "pond_neighborhood_art",
          "cell_art" => {"key" => "forpost_pond", "column" => tile.x - 11, "row" => tile.y - 8}}
      end
      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      expect(rendered).to have_css("[data-cell-art-key='forpost_pond']", count: 25)
      document = Nokogiri::HTML.fragment(rendered)
      [12, 13, 14].each do |x|
        cell = document.at_css("#tile_#{x}_10")
        expect(cell.to_html).to include("world/forpost-pond-landscape", "background-size: 500px 500px")
        expect(cell.to_html).to include("background-position: -#{(x - 11) * 100}px -200px")
      end
    end

    it "renders a physical cell PNG with 100px geometry instead of the master sheet" do
      definition = Game::World::CellArtCatalog.config.fetch("forpost_terrain").merge(
        "slices_directory" => "world/cells/spec-starter"
      )
      allow(Game::World::CellArtCatalog).to receive(:config).and_return("sliced" => definition)
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).and_call_original
      allow(Game::World::CellArtCatalog).to receive(:asset_exists?).with("world/cells/spec-starter/7_9.png").and_return(true)
      allow(view).to receive(:image_path).and_call_original
      allow(view).to receive(:image_path).with("world/cells/spec-starter/7_9.png").and_return("/assets/world/cells/spec-starter/7_9.png")
      tiles = [[OpenStruct.new(x: 9, y: 9, terrain_type: "outdoor", walkable: true,
        metadata: {"cell_art" => {"key" => "sliced", "column" => 7, "row" => 9}})]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      cell = Nokogiri::HTML.fragment(rendered).at_css("#tile_9_9")
      expect(cell["style"]).to include("world/cells/spec-starter/7_9.png", "background-position: 0px 0px", "background-size: 100px 100px")
      expect(cell["data-cell-art-key"]).to eq("sliced")
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

    it "includes server offer fields on clickable tiles" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("[data-action-key='north-key']")
      expect(rendered).to have_css("[data-target-x='10'][data-target-y='9']")
      expect(rendered).to have_css("[data-travel-seconds='30']")
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

    it "uses a semantic button for each clickable cell" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_button("Move north")
      expect(rendered).to have_css("button.nl-tile-clickable--available[data-available='true']", minimum: 4)
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

    it "does not make tiles clickable unless the server offered them" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {},
        movement_destinations: []
      }

      expect(rendered).not_to have_css(".nl-tile-clickable--available")
      expect(rendered).to have_css("td#tile_10_9 .nl-tile-inactive")
    end

    it "disables offered destinations while movement is active" do
      active_movement = OpenStruct.new(remaining_seconds: 17, ends_at: 17.seconds.from_now)

      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {},
        movement_destinations: movement_destinations,
        active_movement: active_movement,
        movement_remaining_seconds: 17
      }

      expect(rendered).to have_css("[data-nl-world-map-movement-active-value='true']")
      expect(rendered).to have_css("[data-nl-world-map-movement-remaining-seconds-value='17']")
      expect(rendered).to have_css(".nl-cursor-img.nl-cursor-img--moving")
      expect(rendered).not_to have_css(".nl-tile-clickable--available")
    end

    it "publishes direction, distance, and duration for the sliding travel animation" do
      active_movement = OpenStruct.new(
        from_x: 10,
        from_y: 10,
        target_x: 11,
        target_y: 9,
        travel_seconds: 30,
        remaining_seconds: 17,
        ends_at: 17.seconds.from_now
      )

      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {},
        movement_destinations: [],
        active_movement: active_movement,
        movement_remaining_seconds: 17
      }

      expect(rendered).to have_css("[data-nl-world-map-movement-delta-x-value='1']")
      expect(rendered).to have_css("[data-nl-world-map-movement-delta-y-value='-1']")
      expect(rendered).to have_css("[data-nl-world-map-movement-total-seconds-value='30']")
    end

    it "publishes the server clock beside the authoritative movement deadline" do
      travel_to Time.utc(2026, 9, 7, 12, 0, 0) do
        render partial: "world/map", locals: {
          position:,
          nearby_tiles:,
          zone:,
          active_movement: OpenStruct.new(ends_at: 17.seconds.from_now),
          movement_remaining_seconds: 17
        }

        expect(rendered).to have_css("[data-nl-world-map-server-now-value='2026-09-07T12:00:00.000Z']")
        expect(rendered).to have_css("[data-nl-world-map-movement-ends-at-value='2026-09-07T12:00:17.000Z']")
      end
    end

    it "renders timed local work with the stationary cursor and no movement controls" do
      render partial: "world/map", locals: {
        position:,
        nearby_tiles:,
        zone:,
        movement_destinations:,
        active_world_action: OpenStruct.new(
          local_action_ends_at: 21.seconds.from_now,
          local_action_remaining_seconds: 21
        )
      }

      expect(rendered).to have_css("[data-nl-world-map-work-active-value='true']")
      expect(rendered).to have_css("[data-nl-world-map-movement-active-value='false']")
      expect(rendered).to have_css(".nl-cursor-img--idle")
      expect(rendered).to have_css(".nl-timer-seconds", text: "21", visible: :all)
      expect(rendered).not_to have_css(".nl-tile-clickable--available")
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

    it "shows remaining seconds while movement is active" do
      active_movement = OpenStruct.new(remaining_seconds: 17, ends_at: 17.seconds.from_now)

      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {},
        active_movement: active_movement,
        movement_remaining_seconds: 17
      }

      expect(rendered).to include("display: block")
      expect(rendered).to have_css(".nl-timer-seconds", text: "17", visible: :all)
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

    it "movement form has server offer inputs" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: nearby_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css("form#movement-form input#movement-target-x", visible: :all)
      expect(rendered).to have_css("form#movement-form input#movement-target-y", visible: :all)
      expect(rendered).to have_css("form#movement-form input#movement-action-key", visible: :all)
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
    it "renders a decorative city entrance icon with its accessible authored name" do
      gate_tiles = [[OpenStruct.new(x: 9, y: 9, terrain_type: "outdoor", walkable: true,
        metadata: {"building" => "City Exit", "building_kind" => "city"})]]

      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: gate_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css('.nl-tile-building--city[title="City Exit"] .nl-tile-city-gate[aria-hidden="true"]', text: "🏰")
      expect(rendered).to have_css(".nl-tile-building--city .nl-entity-label", text: "City Exit", visible: :all)
    end

    it "retains accessible entrance names without duplicating landmarks painted into approved art" do
      definition = Game::World::CellArtCatalog.config.fetch("forpost_terrain").merge(
        "landmarks_in_art" => true, "painted_landmarks" => [
          {"column" => 0, "row" => 0, "building_key" => "village_entrance"},
          {"column" => 1, "row" => 0, "building_key" => "east_gate"}
        ]
      )
      allow(Game::World::CellArtCatalog).to receive(:config).and_return("painted" => definition)
      tiles = [[
        OpenStruct.new(x: 9, y: 9, building_key: "village_entrance", terrain_type: "outdoor", walkable: true, metadata: {
          "building" => "Village Entrance", "building_kind" => "village", "cell_art" => {"key" => "painted"}
        }),
        OpenStruct.new(x: 10, y: 9, building_key: "east_gate", terrain_type: "outdoor", walkable: true, metadata: {
          "building" => "East Gate", "building_kind" => "city", "cell_art" => {"key" => "painted", "column" => 1}
        })
      ]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      expect(rendered).not_to have_css(".nl-tile-village-hut, .nl-tile-city-gate")
      expect(rendered).to have_css(".nl-tile-building--painted", count: 2)
      expect(rendered).to have_css('.nl-tile-building--village[title="Village Entrance"] .nl-entity-label', text: "Village Entrance", visible: :all)
      expect(rendered).to have_css('.nl-tile-building--city[title="East Gate"] .nl-entity-label', text: "East Gate", visible: :all)
    end

    it "keeps the decorative entrance marker when only mutable tile metadata claims painted landmarks" do
      tiles = [[OpenStruct.new(x: 9, y: 9, terrain_type: "outdoor", walkable: true, metadata: {
        "building" => "City Exit", "building_kind" => "city", "landmarks_in_art" => true,
        "cell_art" => {"key" => "forpost_terrain", "landmarks_in_art" => true}
      })]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      expect(rendered).to have_css(".nl-tile-city-gate", text: "🏰")
      expect(rendered).to have_css(".nl-entity-label", text: "City Exit", visible: :all)
    end

    it "shows markers for moved or different entrances even when cell metadata spoofs the painted key" do
      tiles = [[
        OpenStruct.new(x: 7, y: 8, building_key: "outpost_gate", terrain_type: "outdoor", walkable: true, metadata: {
          "building" => "Moved Gate", "building_kind" => "city", "building_key" => "outpost_gate",
          "cell_art" => {"key" => "forpost_starter", "column" => 7, "row" => 6}
        }),
        OpenStruct.new(x: 6, y: 8, building_key: "new_gate", terrain_type: "outdoor", walkable: true, metadata: {
          "building" => "New Gate", "building_kind" => "city", "building_key" => "outpost_gate",
          "cell_art" => {"key" => "forpost_starter", "column" => 6, "row" => 6}
        }),
        OpenStruct.new(x: 4, y: 6, terrain_type: "outdoor", walkable: true, metadata: {
          "building" => "Metadata Only", "building_kind" => "village", "building_key" => "frontier_village_entrance",
          "cell_art" => {"key" => "forpost_starter", "column" => 4, "row" => 4}
        })
      ]]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      expect(rendered).to have_css("#tile_7_8 .nl-tile-city-gate", text: "🏰")
      expect(rendered).to have_css("#tile_6_8 .nl-tile-city-gate", text: "🏰")
      expect(rendered).to have_css("#tile_4_6 .nl-tile-village-hut")
      expect(rendered).not_to have_css(".nl-tile-building--painted")
    end

    it "shows semantic labels for mine and exchange entrances absent from the painted slice" do
      tiles = [%w[mine exchange].each_with_index.map do |kind, index|
        OpenStruct.new(x: 7 + index, y: 8, building_key: "managed_#{kind}", terrain_type: "outdoor", walkable: true,
          metadata: {"building" => "Managed #{kind}", "building_kind" => kind,
            "cell_art" => {"key" => "forpost_starter", "column" => 7 + index, "row" => 6}})
      end]

      render partial: "world/map", locals: {position:, nearby_tiles: tiles, zone:, tile_data: {}}

      expect(rendered).to have_css("#tile_7_8 .nl-entity-label:not(.nl-visually-hidden)", text: "Managed mine")
      expect(rendered).to have_css("#tile_8_8 .nl-entity-label:not(.nl-visually-hidden)", text: "Managed exchange")
      expect(rendered).not_to have_css(".nl-tile-building--painted")
    end

    context "with NPC on a tile" do
      let(:nearby_tiles_with_npc) do
        tiles = nearby_tiles
        tiles[1][1] = OpenStruct.new(
          x: 9,
          y: 9,
          terrain_type: "outdoor",
          walkable: true,
          metadata: {"npc" => "Plague Rat"}
        )
        tiles
      end

      it "does not reveal an NPC marker" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_npc,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).not_to have_css(".nl-tile-npc")
      end

      it "does not reveal the NPC name" do
        render partial: "world/map", locals: {
          position: position,
          nearby_tiles: nearby_tiles_with_npc,
          zone: zone,
          tile_data: {}
        }

        expect(rendered).not_to include("Plague Rat")
      end
    end
  end

  describe "terrain type" do
    let(:outdoor_tiles) do
      [
        [
          OpenStruct.new(x: 8, y: 8, terrain_type: "outdoor", walkable: true, metadata: {}),
          OpenStruct.new(x: 9, y: 8, terrain_type: "outdoor", walkable: true, metadata: {}),
          OpenStruct.new(x: 10, y: 8, terrain_type: "outdoor", walkable: false, metadata: {})
        ],
        [
          OpenStruct.new(x: 8, y: 9, terrain_type: "outdoor", walkable: false, metadata: {}),
          OpenStruct.new(x: 9, y: 9, terrain_type: "outdoor", walkable: true, metadata: {}),
          OpenStruct.new(x: 10, y: 9, terrain_type: "outdoor", walkable: true, metadata: {})
        ]
      ]
    end

    it "renders the source-backed outdoor location class" do
      render partial: "world/map", locals: {
        position: position,
        nearby_tiles: outdoor_tiles,
        zone: zone,
        tile_data: {}
      }

      expect(rendered).to have_css(".nl-tile-bg--outdoor")
      expect(rendered).not_to have_css(".nl-tile-bg--city")
      expect(rendered).not_to have_css(".nl-tile-bg--road")
      expect(rendered).not_to have_css(".nl-tile-bg--plaza")
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
            terrain_type: "outdoor",
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
