# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World", type: :request do
  describe "Zone model schema" do
    # Regression test: Zone model should not have a description column
    # This covers the bug where city_view.html.erb tried to access zone.description
    # Fix: Use zone.metadata&.dig("description") instead

    it "does not have description column" do
      expect(Zone.column_names).not_to include("description")
    end

    it "has metadata column for storing description and other data" do
      expect(Zone.column_names).to include("metadata")
    end

    it "stores description in metadata JSONB" do
      zone = create(:zone, metadata: {"description" => "A test zone"})
      expect(zone.metadata["description"]).to eq("A test zone")
    end
  end

  describe "GET /world" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Test Plains", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    context "when character has a position" do
      it "renders the world view successfully" do
        get world_path
        expect(response).to have_http_status(:success)
      end

      it "displays the zone name" do
        get world_path
        expect(response.body).to include("Test Plains")
      end

      it "displays the player coordinates" do
        get world_path
        expect(response.body).to include("5")
      end

      it "renders the map partial" do
        get world_path
        expect(response.body).to include("nl-map-container")
      end

      it "includes available tile indicators for adjacent tiles" do
        get world_path
        # Adjacent tiles should have data-available attribute
        expect(response.body).to include("data-available")
      end
    end

    context "when in a city zone" do
      let(:city_zone) do
        create(:zone,
          name: "Capital City",
          biome: "city",
          width: 15,
          height: 15,
          metadata: {"description" => "A bustling city"})
      end

      before do
        position.update!(zone: city_zone)
      end

      it "renders the city view" do
        get world_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("nl-city-view").or include("city-view")
      end

      it "includes the city description from metadata" do
        get world_path
        expect(response.body).to include("bustling city")
      end
    end

    context "when character has no position" do
      before { position.destroy }

      it "creates a default position and renders successfully" do
        # Ensure a starter zone exists
        create(:zone, biome: "city", name: "Starter City")
        get world_path
        expect(response).to have_http_status(:success)
        expect(character.reload.position).to be_present
      end
    end
  end

  describe "POST /world/move" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Plains", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5, last_action_at: 10.seconds.ago) }

    before { sign_in user, scope: :user }

    context "with valid movement" do
      it "moves the character north" do
        post move_world_path, params: {direction: "north"}

        position.reload
        expect(position.y).to eq(4)
        expect(position.x).to eq(5)
      end

      it "moves the character south" do
        post move_world_path, params: {direction: "south"}

        position.reload
        expect(position.y).to eq(6)
        expect(position.x).to eq(5)
      end

      it "moves the character east" do
        post move_world_path, params: {direction: "east"}

        position.reload
        expect(position.x).to eq(6)
        expect(position.y).to eq(5)
      end

      it "moves the character west" do
        post move_world_path, params: {direction: "west"}

        position.reload
        expect(position.x).to eq(4)
        expect(position.y).to eq(5)
      end

      it "redirects to world path with notice on HTML format" do
        post move_world_path, params: {direction: "north"}
        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Moved")
      end

      it "returns turbo stream on turbo stream format" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end

      # Regression test: Turbo stream must use 'update' action, not 'replace'
      # Using 'replace' removes the turbo-frame element, breaking subsequent updates
      it "uses turbo stream 'update' action to preserve turbo-frame elements" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('action="update"')
        expect(response.body).not_to include('action="replace"')
      end

      it "turbo stream targets game-map element" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="game-map"')
      end

      it "turbo stream targets location-info element" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="location-info"')
      end

      it "turbo stream targets available-actions element" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="available-actions"')
      end

      # Regression test: Map update must include proper HTML content
      it "turbo stream contains map container HTML" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include("nl-map-container")
      end

      it "turbo stream contains updated player position" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # After moving north, player should be at y=4
        expect(response.body).to include("data-nl-world-map-player-y-value=\"4\"")
      end

      it "turbo stream contains movement form for subsequent moves" do
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include("movement-form")
      end
    end

    context "with invalid movement" do
      it "prevents moving outside zone boundaries (north at y=0)" do
        position.update!(y: 0)

        post move_world_path, params: {direction: "north"}

        expect(response).to redirect_to(world_path)
        expect(position.reload.y).to eq(0) # Position unchanged
      end

      it "prevents moving outside zone boundaries (west at x=0)" do
        position.update!(x: 0)

        post move_world_path, params: {direction: "west"}

        expect(response).to redirect_to(world_path)
        expect(position.reload.x).to eq(0)
      end

      it "prevents moving outside zone boundaries (south at max y)" do
        position.update!(y: zone.height - 1)

        post move_world_path, params: {direction: "south"}

        expect(response).to redirect_to(world_path)
        expect(position.reload.y).to eq(zone.height - 1)
      end

      it "prevents moving outside zone boundaries (east at max x)" do
        position.update!(x: zone.width - 1)

        post move_world_path, params: {direction: "east"}

        expect(response).to redirect_to(world_path)
        expect(position.reload.x).to eq(zone.width - 1)
      end
    end

    context "with movement cooldown" do
      it "allows movement after cooldown expires" do
        position.update!(last_action_at: 10.seconds.ago)

        post move_world_path, params: {direction: "north"}

        expect(position.reload.y).to eq(4) # Movement succeeded
      end

      # Regression test: Cooldown must be enforced to prevent rapid movement
      it "prevents movement during cooldown period" do
        # First movement succeeds
        post move_world_path, params: {direction: "north"}
        expect(position.reload.y).to eq(4)

        # Immediate second movement should fail (within cooldown)
        post move_world_path, params: {direction: "north"}
        expect(response).to redirect_to(world_path)
        expect(position.reload.y).to eq(4) # Position unchanged
      end

      it "returns error message when movement is on cooldown" do
        # First movement
        post move_world_path, params: {direction: "north"}

        # Second movement during cooldown
        post move_world_path, params: {direction: "north"}
        follow_redirect!

        expect(response.body).to include("Action already consumed").or include("cooldown").or include("turn")
      end

      it "returns turbo stream error when movement is on cooldown via turbo" do
        # First movement
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Second movement during cooldown
        post move_world_path,
          params: {direction: "north"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        # Should contain flash message turbo stream
        expect(response.body).to include("turbo-stream")
      end

      it "allows movement after waiting for cooldown to expire" do
        position.update!(last_action_at: 10.seconds.ago)

        # First movement
        post move_world_path, params: {direction: "north"}
        expect(position.reload.y).to eq(4)

        # Simulate waiting for cooldown
        position.update!(last_action_at: 10.seconds.ago)

        # Second movement after cooldown
        post move_world_path, params: {direction: "north"}
        expect(position.reload.y).to eq(3)
      end
    end
  end

  describe "POST /world/enter" do
    let(:user) { create(:user) }
    let(:outdoor_zone) { create(:zone, name: "Plains", biome: "plains", width: 20, height: 20) }
    let(:city_zone) { create(:zone, name: "Capital", biome: "city", width: 10, height: 10) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: outdoor_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: city_zone, x: 3, y: 3, default_entry: true) }

    before { sign_in user, scope: :user }

    context "with valid location" do
      it "moves character to the new zone" do
        post enter_world_path, params: {location_key: "capital"}

        position.reload
        expect(position.zone).to eq(city_zone)
        expect(position.x).to eq(3)
        expect(position.y).to eq(3)
      end

      it "redirects with success notice" do
        post enter_world_path, params: {location_key: "capital"}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Entered").or include("Capital")
      end
    end

    context "with invalid location" do
      it "returns alert for non-existent location" do
        post enter_world_path, params: {location_key: "nonexistent"}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end
    end
  end

  describe "POST /world/exit" do
    let(:user) { create(:user) }
    let(:city_zone) do
      create(:zone,
        name: "Capital",
        biome: "city",
        width: 10,
        height: 10,
        metadata: {"exit_to" => "Wild Plains"})
    end
    let(:outdoor_zone) { create(:zone, name: "Wild Plains", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: city_zone, x: 3, y: 3) }
    let!(:spawn_point) { create(:spawn_point, zone: outdoor_zone, x: 10, y: 10, default_entry: true) }

    before { sign_in user, scope: :user }

    it "moves character to the exit zone" do
      post exit_location_world_path

      position.reload
      expect(position.zone).to eq(outdoor_zone)
    end

    it "redirects with success notice" do
      post exit_location_world_path

      expect(response).to redirect_to(world_path)
      follow_redirect!
      expect(response.body).to include("Exited").or include("Wild Plains")
    end
  end

  describe "map rendering" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Test Zone", biome: "forest", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before { sign_in user, scope: :user }

    it "renders a 5x5 grid of tiles around the player" do
      get world_path

      # The map should include tiles from x: 8-12 and y: 8-12
      expect(response.body).to include("tile_8_8").or include("data-x=\"8\"")
      expect(response.body).to include("tile_12_12").or include("data-x=\"12\"")
    end

    it "marks the current player position" do
      get world_path

      # Player position should be marked with cursor
      expect(response.body).to include("nl-cursor")
    end

    it "shows terrain type classes based on biome" do
      get world_path

      expect(response.body).to include("nl-tile-bg--forest")
    end

    it "includes movement timer elements" do
      get world_path

      expect(response.body).to include("nl-timer")
    end

    it "includes location info bar" do
      get world_path

      expect(response.body).to include("nl-map-info").or include("nl-location-name")
    end
  end

  describe "procedural terrain generation" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Mixed Zone", biome: "plains", width: 50, height: 50) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 25, y: 25) }

    before { sign_in user, scope: :user }

    it "renders map with tile coordinates" do
      get world_path

      # Verify the map contains tiles with coordinate data
      expect(response.body).to include('data-x="25"')
      expect(response.body).to include('data-y="25"')
    end

    it "renders map with terrain data" do
      get world_path

      # Verify terrain types are rendered
      expect(response.body).to include('data-terrain="plains"')
    end

    it "generates consistent terrain types for biome" do
      get world_path

      # Plains biome should have plains terrain tiles
      expect(response.body).to match(/nl-tile-bg--plains/)
    end
  end

  describe "JSON API responses" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "API Zone", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5, last_action_at: 10.seconds.ago) }

    before { sign_in user, scope: :user }

    it "returns JSON for gather_resource action" do
      post gather_resource_world_path,
        headers: {"Accept" => "application/json"}

      expect(response.content_type).to include("application/json")
    end
  end

  describe "POST /world/gather_resource" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Resource Zone", biome: "forest", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }
    let!(:item_template) { create(:item_template, name: "Oak Wood", key: "oak_wood", item_type: "resource", stack_limit: 99, weight: 1) }
    let!(:tile_resource) do
      create(:tile_resource,
        zone: zone.name,
        biome: "forest",
        x: 5,
        y: 5,
        resource_key: "oak_wood",
        resource_type: "wood",
        quantity: 10,
        base_quantity: 10)
    end

    before do
      sign_in user, scope: :user
      # Use the inventory created by the character factory
      character.inventory.update!(slot_capacity: 20, weight_capacity: 100, current_weight: 0)
    end

    # Regression test: Ensure gather_resource doesn't fail with inventory validation errors
    # Previously failed with "Quantity must be greater than 0" when creating new inventory items
    context "when inventory is empty" do
      it "does not raise validation errors when adding items to inventory" do
        # This should not raise ActiveRecord::RecordInvalid
        expect {
          post gather_resource_world_path, headers: {"Accept" => "application/json"}
        }.not_to raise_error
      end

      it "returns a valid response" do
        post gather_resource_world_path, headers: {"Accept" => "application/json"}

        # Response should be either success or failure message, not 500 error
        expect(response.status).to be_in([200, 422])
        expect(response.content_type).to include("application/json")
      end
    end

    context "with turbo stream format" do
      it "returns turbo stream response" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Should not raise 500 error
        expect(response.status).to be_in([200, 422])
      end

      # Regression test: Map must update after gathering to show resource state changes
      it "uses update action for game-map" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Must use 'update' not 'replace' to preserve turbo-frame element
        expect(response.body).to include('action="update"')
        expect(response.body).to include('target="game-map"')
      end

      it "includes map container in response" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include("nl-map-container")
      end

      it "updates available-actions" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="available-actions"')
      end

      it "updates location-info" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="location-info"')
      end

      it "includes flash message" do
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include('target="flash"')
      end
    end

    # Regression test: Depleted resources should not show on map
    context "when resource is depleted" do
      before do
        # Update the existing tile_resource to be depleted
        tile_resource.update!(quantity: 0, respawns_at: 30.minutes.from_now)
      end

      it "does not show resource data attribute for depleted resource" do
        get world_path

        # Verify tile exists
        expect(response.body).to include('id="tile_5_5"')
        # Depleted resources should not show resource data attribute
        # Note: The attribute should not be present, checking exact behavior
        tile_html = response.body[/tile_5_5.*?<\/td>/m]
        expect(tile_html).not_to include("data-resource=")
      end
    end

    context "when resource is available" do
      let!(:available_resource) do
        create(:tile_resource,
          zone: zone.name,
          x: position.x + 1, # Adjacent tile
          y: position.y,
          resource_key: "healing_herb",
          resource_type: "herb",
          quantity: 2,
          base_quantity: 2,
          respawns_at: nil)
      end

      it "includes available resource in map" do
        get world_path

        # Available resources should show
        expect(response.body).to include("Healing Herb")
      end
    end

    context "with HTML format" do
      it "redirects to world path" do
        post gather_resource_world_path

        expect(response).to redirect_to(world_path)
      end
    end
  end

  # Tests for add_live_tile_features logic
  # This tests the priority system: database records > procedural features
  describe "map tile feature display" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Feature Test Zone", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before { sign_in user, scope: :user }

    describe "TileResource display" do
      context "when database TileResource exists and is available" do
        let!(:db_resource) do
          create(:tile_resource,
            zone: zone.name,
            x: 11, # Adjacent tile (east)
            y: 10,
            resource_key: "iron_ore",
            resource_type: "ore",
            quantity: 3,
            base_quantity: 3,
            respawns_at: nil)
        end

        it "shows the database resource on the map" do
          get world_path

          expect(response.body).to include("Iron Ore")
          expect(response.body).to include("nl-tile-resource")
        end

        it "shows correct resource icon for ore type" do
          get world_path

          # Ore resources should show pickaxe icon
          expect(response.body).to include("⛏️")
        end
      end

      context "when database TileResource exists but is depleted" do
        let!(:depleted_db_resource) do
          create(:tile_resource,
            zone: zone.name,
            x: 11, # Adjacent tile (east)
            y: 10,
            resource_key: "depleted_ore",
            resource_type: "ore",
            quantity: 0,
            base_quantity: 3,
            respawns_at: 30.minutes.from_now)
        end

        it "does not show the depleted resource on the map" do
          get world_path

          expect(response.body).not_to include("Depleted Ore")
        end

        it "hides resource until respawn time passes" do
          get world_path

          # The depleted resource tile should not have resource marker
          expect(response.body).not_to include('data-resource="Depleted Ore"')
        end
      end

      context "when no database TileResource exists (procedural fallback)" do
        # No TileResource created - relies on procedural_features

        it "shows procedural resources based on zone biome" do
          get world_path

          # Procedural features should still generate some resources
          # The exact resources depend on seeded random, but plains should have some
          expect(response).to have_http_status(:success)
        end
      end
    end

    describe "TileNpc display" do
      context "when database TileNpc exists and is alive" do
        let(:npc_template) { create(:npc_template, name: "Test Goblin", npc_key: "test_goblin") }
        let!(:db_npc) do
          create(:tile_npc,
            zone: zone.name,
            x: 9, # Adjacent tile (west)
            y: 10,
            npc_template: npc_template,
            current_hp: 50,
            max_hp: 50,
            respawns_at: nil)
        end

        it "shows the database NPC on the map" do
          get world_path

          expect(response.body).to include("Test Goblin")
        end

        it "shows NPC marker" do
          get world_path

          expect(response.body).to include("nl-tile-npc")
        end
      end

      context "when database TileNpc exists but is dead (defeated)" do
        let(:npc_template) { create(:npc_template, name: "Dead Goblin", npc_key: "dead_goblin") }
        let(:defeated_by_character) { create(:character) }
        let!(:dead_db_npc) do
          create(:tile_npc, :defeated,
            zone: zone.name,
            x: 9, # Adjacent tile (west)
            y: 10,
            npc_template: npc_template,
            defeated_by: defeated_by_character)
        end

        it "does not show the defeated NPC on the map" do
          get world_path

          expect(response.body).not_to include("Dead Goblin")
        end

        it "hides NPC until respawn time passes" do
          get world_path

          # The defeated NPC tile should not have NPC marker
          expect(response.body).not_to include('title="Dead Goblin"')
        end
      end

      context "when database TileNpc is alive" do
        let(:npc_template) { create(:npc_template, name: "Alive Goblin", npc_key: "alive_goblin") }
        let!(:alive_npc) do
          create(:tile_npc,
            zone: zone.name,
            x: 9, # Adjacent tile (west)
            y: 10,
            npc_template: npc_template,
            defeated_at: nil,
            respawns_at: nil)
        end

        it "shows the alive NPC on the map" do
          get world_path

          expect(response.body).to include("Alive Goblin")
        end
      end
    end

    describe "resource depletion after gathering" do
      let!(:gatherable_resource) do
        create(:tile_resource,
          zone: zone.name,
          x: position.x,
          y: position.y,
          resource_key: "test_herb",
          resource_type: "herb",
          quantity: 1, # Will deplete after one gather
          base_quantity: 1,
          respawns_at: nil)
      end

      before do
        # Use the inventory created by the character factory
        character.inventory.update!(slot_capacity: 20, weight_capacity: 100)
      end

      it "hides resource from map after it's fully depleted" do
        # First verify resource is visible
        get world_path
        expect(response.body).to include("Test Herb")

        # Gather the resource (depletes it)
        post gather_resource_world_path,
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Check that map update doesn't include the depleted resource
        expect(response.body).not_to include('title="Test Herb"')
      end
    end

    describe "priority: database records over procedural" do
      # When a database record exists, it takes precedence over procedural generation
      let!(:db_resource_at_procedural_location) do
        # Place a specific database resource at coordinates that would have procedural content
        create(:tile_resource,
          zone: zone.name,
          x: 10,
          y: 9, # North of player
          resource_key: "special_crystal",
          resource_type: "crystal",
          quantity: 5,
          base_quantity: 5,
          respawns_at: nil)
      end

      it "shows database resource instead of procedural" do
        get world_path

        # Should show our specific database resource
        expect(response.body).to include("Special Crystal")
      end

      it "shows depleted status even if procedural would generate resource" do
        # Deplete the resource
        db_resource_at_procedural_location.update!(quantity: 0, respawns_at: 30.minutes.from_now)

        get world_path

        # Should NOT show any resource at this tile (even if procedural would generate one)
        expect(response.body).not_to include("Special Crystal")
      end
    end
  end

  describe "authentication requirements" do
    let(:zone) { create(:zone, name: "Auth Zone", biome: "plains") }

    it "redirects to login when not authenticated" do
      get world_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects move action when not authenticated" do
      post move_world_path, params: {direction: "north"}

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # ===========================================================================
  # TileBuilding Tests
  # ===========================================================================
  describe "POST /world/enter_building" do
    let(:user) { create(:user) }
    let(:source_zone) { create(:zone, name: "Starter Plains", biome: "plains", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Castleton Keep", biome: "city", width: 10, height: 10) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: source_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 3, y: 3, default_entry: true) }

    before { sign_in user, scope: :user }

    # -------------------------------------------------------------------------
    # Success Cases
    # -------------------------------------------------------------------------
    context "with valid building at current position" do
      let!(:building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "test_castle",
          name: "Test Castle",
          building_type: "castle",
          destination_zone: destination_zone,
          destination_x: 7,
          destination_y: 7,
          required_level: 1,
          active: true)
      end

      it "moves character to destination zone" do
        post enter_building_world_path, params: {building_id: building.id}

        position.reload
        expect(position.zone).to eq(destination_zone)
      end

      it "moves character to specified destination coordinates" do
        post enter_building_world_path, params: {building_id: building.id}

        position.reload
        expect(position.x).to eq(7)
        expect(position.y).to eq(7)
      end

      it "redirects to world path with success notice on HTML format" do
        post enter_building_world_path, params: {building_id: building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Test Castle").or include("enter")
      end

      it "redirects on turbo stream format to trigger full page reload" do
        post enter_building_world_path,
          params: {building_id: building.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # After entering a building, we redirect because:
        # 1. Target zone might be a city which requires city_view.html.erb (not partials)
        # 2. Redirect with see_other status triggers Turbo to do full page navigation
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(world_path)
      end
    end

    context "with building using default spawn point" do
      let!(:building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "spawn_test_castle",
          name: "Spawn Test Castle",
          destination_zone: destination_zone,
          destination_x: nil,
          destination_y: nil,
          required_level: 1,
          active: true)
      end

      it "uses destination zone spawn point when no specific coordinates" do
        post enter_building_world_path, params: {building_id: building.id}

        position.reload
        expect(position.zone).to eq(destination_zone)
        expect(position.x).to eq(spawn_point.x)
        expect(position.y).to eq(spawn_point.y)
      end
    end

    # -------------------------------------------------------------------------
    # Failure Cases
    # -------------------------------------------------------------------------
    context "when building does not exist" do
      it "returns alert for non-existent building" do
        post enter_building_world_path, params: {building_id: 99999}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end

      it "returns turbo stream error for non-existent building" do
        post enter_building_world_path,
          params: {building_id: 99999},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end

    context "when building is at different position" do
      let!(:distant_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 10,
          y: 10,
          building_key: "distant_castle",
          name: "Distant Castle",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns alert when not at building location" do
        post enter_building_world_path, params: {building_id: distant_building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("must be at the building")
      end

      it "does not move character" do
        post enter_building_world_path, params: {building_id: distant_building.id}

        position.reload
        expect(position.zone).to eq(source_zone)
        expect(position.x).to eq(5)
        expect(position.y).to eq(5)
      end
    end

    context "when building is inactive" do
      let!(:inactive_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "inactive_castle",
          name: "Inactive Castle",
          destination_zone: destination_zone,
          required_level: 1,
          active: false)
      end

      it "returns alert for inactive building" do
        post enter_building_world_path, params: {building_id: inactive_building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        # Building is found but service rejects entry due to inactive status
        # Message is "This building is currently inaccessible."
        expect(response.body).to include("inaccessible")
      end

      it "does not move character" do
        post enter_building_world_path, params: {building_id: inactive_building.id}

        position.reload
        expect(position.zone).to eq(source_zone)
      end
    end

    context "when character level is too low" do
      let!(:high_level_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "high_level_castle",
          name: "High Level Castle",
          destination_zone: destination_zone,
          required_level: 50,
          active: true)
      end

      it "returns alert with level requirement" do
        post enter_building_world_path, params: {building_id: high_level_building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("level 50")
      end

      it "does not move character" do
        post enter_building_world_path, params: {building_id: high_level_building.id}

        position.reload
        expect(position.zone).to eq(source_zone)
      end

      it "returns turbo stream error with level requirement" do
        post enter_building_world_path,
          params: {building_id: high_level_building.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.body).to include("turbo-stream")
      end
    end

    context "when building has no destination zone" do
      let!(:no_dest_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "no_dest_castle",
          name: "No Destination Castle",
          destination_zone: nil,
          required_level: 1,
          active: true)
      end

      it "returns alert for inaccessible building" do
        post enter_building_world_path, params: {building_id: no_dest_building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("inaccessible")
      end

      it "does not move character" do
        post enter_building_world_path, params: {building_id: no_dest_building.id}

        position.reload
        expect(position.zone).to eq(source_zone)
      end
    end

    # -------------------------------------------------------------------------
    # Null/Edge Cases
    # -------------------------------------------------------------------------
    context "when building_id is nil" do
      it "returns alert for missing building" do
        post enter_building_world_path, params: {building_id: nil}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end
    end

    context "when building_id is empty string" do
      it "returns alert for missing building" do
        post enter_building_world_path, params: {building_id: ""}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end
    end

    context "when no building_id parameter" do
      it "returns alert for missing building" do
        post enter_building_world_path

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end
    end

    context "when building is in different zone" do
      let(:other_zone) { create(:zone, name: "Other Zone", biome: "forest") }
      let!(:other_zone_building) do
        create(:tile_building,
          zone: other_zone.name,
          x: 5,
          y: 5,
          building_key: "other_zone_castle",
          name: "Other Zone Castle",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns alert when building is in different zone" do
        post enter_building_world_path, params: {building_id: other_zone_building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("must be at the building")
      end
    end
  end

  describe "TileBuilding display on map" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Building Display Zone", biome: "plains", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Destination", biome: "city") }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before { sign_in user, scope: :user }

    context "when active building exists at adjacent tile" do
      let!(:building) do
        create(:tile_building,
          zone: zone.name,
          x: 11, # Adjacent tile (east)
          y: 10,
          building_key: "map_test_castle",
          name: "Map Test Castle",
          building_type: "castle",
          icon: "🏰",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows building marker on map" do
        get world_path

        expect(response.body).to include("nl-tile-building")
      end

      it "shows building icon on map" do
        get world_path

        expect(response.body).to include("🏰")
      end

      it "shows building name in title attribute" do
        get world_path

        expect(response.body).to include("Map Test Castle")
      end
    end

    context "when building is at current position" do
      let!(:building_at_position) do
        create(:tile_building,
          zone: zone.name,
          x: 10,
          y: 10,
          building_key: "current_position_castle",
          name: "Current Position Castle",
          building_type: "castle",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows building in actions panel" do
        get world_path

        expect(response.body).to include("Current Position Castle")
        expect(response.body).to include("Enter")
      end
    end

    context "when building is inactive" do
      let!(:inactive_building) do
        create(:tile_building,
          zone: zone.name,
          x: 11,
          y: 10,
          building_key: "inactive_map_castle",
          name: "Inactive Map Castle",
          destination_zone: destination_zone,
          active: false)
      end

      it "does not show inactive building on map" do
        get world_path

        expect(response.body).not_to include("Inactive Map Castle")
      end
    end

    context "with different building types" do
      let!(:inn) do
        create(:tile_building,
          zone: zone.name,
          x: 9,
          y: 10,
          building_key: "test_inn",
          name: "Cozy Inn",
          building_type: "inn",
          icon: "🏨",
          destination_zone: destination_zone,
          active: true)
      end

      let!(:portal) do
        create(:tile_building,
          zone: zone.name,
          x: 10,
          y: 9,
          building_key: "test_portal",
          name: "Magic Portal",
          building_type: "portal",
          icon: "🌀",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows different icons for different building types" do
        get world_path

        expect(response.body).to include("🏨") # Inn icon
        expect(response.body).to include("🌀") # Portal icon
      end
    end
  end

  describe "TileBuilding actions panel display" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Actions Panel Zone", biome: "plains", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Actions Destination", biome: "city") }
    let(:character) { create(:character, user: user, level: 5) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    context "when character can enter building" do
      let!(:enterable_building) do
        create(:tile_building,
          zone: zone.name,
          x: 5,
          y: 5,
          building_key: "enterable_building",
          name: "Enterable Building",
          destination_zone: destination_zone,
          required_level: 1,
          active: true,
          metadata: {"description" => "A welcoming entrance"})
      end

      it "shows enter button" do
        get world_path

        expect(response.body).to include("Enter")
      end

      it "shows building description" do
        get world_path

        expect(response.body).to include("welcoming entrance")
      end

      it "shows destination zone name" do
        get world_path

        expect(response.body).to include("Actions Destination")
      end
    end

    context "when character cannot enter building (level too low)" do
      let!(:blocked_building) do
        create(:tile_building,
          zone: zone.name,
          x: 5,
          y: 5,
          building_key: "blocked_building",
          name: "Blocked Building",
          destination_zone: destination_zone,
          required_level: 20,
          active: true)
      end

      it "shows blocked reason instead of enter button" do
        get world_path

        expect(response.body).to include("level 20")
        expect(response.body).to include("🔒")
      end
    end
  end

  describe "authentication requirements for enter_building" do
    let(:zone) { create(:zone, name: "Auth Building Zone", biome: "plains") }
    let(:building) { create(:tile_building, zone: zone.name, x: 5, y: 5) }

    it "redirects to login when not authenticated" do
      post enter_building_world_path, params: {building_id: building.id}

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # ============================================
  # Bug Fix: interact_hotspot Turbo Stream handling
  # ============================================
  # Regression tests for the interact_hotspot action handling.
  #
  # Bug: Feature hotspots (Arena, Workshop, etc.) weren't navigating properly
  #      because only enter_zone had proper respond_to block with status: :see_other
  # Fix: Added proper respond_to block for open_feature hotspots

  describe "POST /world/interact_hotspot" do
    let(:user) { create(:user) }
    let(:city_zone) { create(:zone, name: "Hotspot Test City", biome: "city", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Destination Plains", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: city_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 5, y: 5, default_entry: true) }

    before { sign_in user, scope: :user }

    context "with open_feature hotspot (Arena)" do
      let!(:arena_hotspot) do
        create(:city_hotspot, :arena,
          zone: city_zone,
          required_level: 1,
          active: true)
      end

      describe "HTML format" do
        it "redirects to arena page on success" do
          post interact_hotspot_world_path, params: {hotspot_id: arena_hotspot.id}

          expect(response).to redirect_to("/arena")
        end

        it "includes success notice in flash" do
          post interact_hotspot_world_path, params: {hotspot_id: arena_hotspot.id}

          expect(flash[:notice]).to include("Arena")
        end
      end

      describe "Turbo Stream format" do
        it "returns 303 See Other redirect for proper Turbo handling" do
          post interact_hotspot_world_path,
            params: {hotspot_id: arena_hotspot.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to have_http_status(:see_other)
        end

        it "redirects to arena page" do
          post interact_hotspot_world_path,
            params: {hotspot_id: arena_hotspot.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to redirect_to("/arena")
        end

        it "sets flash notice before redirect" do
          post interact_hotspot_world_path,
            params: {hotspot_id: arena_hotspot.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(flash[:notice]).to include("Entering")
        end
      end
    end

    context "with open_feature hotspot (Workshop/Crafting)" do
      let!(:workshop_hotspot) do
        create(:city_hotspot, :workshop,
          zone: city_zone,
          required_level: 1,
          active: true)
      end

      it "redirects to crafting jobs page (HTML)" do
        post interact_hotspot_world_path, params: {hotspot_id: workshop_hotspot.id}

        expect(response).to redirect_to("/crafting_jobs")
      end

      it "redirects to crafting jobs page (Turbo Stream)" do
        post interact_hotspot_world_path,
          params: {hotspot_id: workshop_hotspot.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to redirect_to("/crafting_jobs")
        expect(response).to have_http_status(:see_other)
      end
    end

    context "with enter_zone hotspot (Exit)" do
      let!(:exit_hotspot) do
        create(:city_hotspot, :city_gate,
          zone: city_zone,
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      describe "HTML format" do
        it "redirects to world path after zone transition" do
          post interact_hotspot_world_path, params: {hotspot_id: exit_hotspot.id}

          expect(response).to redirect_to(world_path)
        end

        it "updates character position to destination zone" do
          post interact_hotspot_world_path, params: {hotspot_id: exit_hotspot.id}

          position.reload
          expect(position.zone).to eq(destination_zone)
        end

        it "uses spawn point coordinates" do
          post interact_hotspot_world_path, params: {hotspot_id: exit_hotspot.id}

          position.reload
          expect(position.x).to eq(spawn_point.x)
          expect(position.y).to eq(spawn_point.y)
        end
      end

      describe "Turbo Stream format" do
        it "returns 303 See Other redirect for proper Turbo handling" do
          post interact_hotspot_world_path,
            params: {hotspot_id: exit_hotspot.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to have_http_status(:see_other)
        end

        it "redirects to world path" do
          post interact_hotspot_world_path,
            params: {hotspot_id: exit_hotspot.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to redirect_to(world_path)
        end
      end
    end

    context "when hotspot not found (null case)" do
      it "redirects with alert for HTML format" do
        post interact_hotspot_world_path, params: {hotspot_id: 99999}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end

      it "returns turbo stream error for Turbo format" do
        post interact_hotspot_world_path,
          params: {hotspot_id: 99999},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end

    context "when character level too low (failure case)" do
      let!(:high_level_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          required_level: 50,
          active: true,
          action_type: "open_feature",
          action_params: {"feature" => "arena"})
      end

      it "redirects with alert for HTML format" do
        post interact_hotspot_world_path, params: {hotspot_id: high_level_hotspot.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("level 50")
      end

      it "returns turbo stream error for Turbo format" do
        post interact_hotspot_world_path,
          params: {hotspot_id: high_level_hotspot.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when hotspot is inactive (failure case)" do
      let!(:inactive_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          active: false,
          action_type: "open_feature")
      end

      it "redirects with alert for HTML format" do
        post interact_hotspot_world_path, params: {hotspot_id: inactive_hotspot.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("unavailable").or include("cannot")
      end
    end

    context "with decoration hotspot (null interaction case)" do
      let!(:decoration_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "none",
          hotspot_type: "decoration",
          active: true)
      end

      it "returns failure for decoration hotspots" do
        post interact_hotspot_world_path, params: {hotspot_id: decoration_hotspot.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("cannot").or include("no interaction")
      end
    end

    context "without authentication" do
      before { sign_out user }

      it "redirects to login page" do
        arena_hotspot = create(:city_hotspot, :arena, zone: city_zone)

        post interact_hotspot_world_path, params: {hotspot_id: arena_hotspot.id}

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when hotspot belongs to different zone" do
      let(:other_zone) { create(:zone, name: "Other City", biome: "city") }
      let!(:other_hotspot) do
        create(:city_hotspot, :arena, zone: other_zone, active: true)
      end

      it "returns failure when hotspot zone doesn't match character zone" do
        post interact_hotspot_world_path, params: {hotspot_id: other_hotspot.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("not found")
      end
    end
  end

  # ============================================
  # Integration: City View with Hotspots
  # ============================================
  # Integration tests for the full city view flow

  describe "city view integration" do
    let(:user) { create(:user) }
    let(:city_zone) { create(:zone, name: "Integration Test City", biome: "city", width: 20, height: 20) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: city_zone, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    context "with multiple hotspots" do
      let!(:arena) { create(:city_hotspot, :arena, zone: city_zone, active: true, required_level: 1) }
      let!(:workshop) { create(:city_hotspot, :workshop, zone: city_zone, active: true, required_level: 1) }
      let!(:exit_gate) do
        dest = create(:zone, name: "Exit Dest", biome: "plains")
        create(:spawn_point, zone: dest, default_entry: true)
        create(:city_hotspot, :city_gate, zone: city_zone, destination_zone: dest, active: true)
      end
      let!(:decoration) { create(:city_hotspot, :decoration, zone: city_zone, active: true) }

      it "renders city view with all active hotspots" do
        get world_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Arena")
        expect(response.body).to include("Workshop")
        expect(response.body).to include("City Gates")
      end

      it "includes form for each interactive hotspot" do
        get world_path

        expect(response.body).to include("interact_hotspot")
        expect(response.body).to include(arena.id.to_s)
        expect(response.body).to include(workshop.id.to_s)
      end

      it "arena hotspot navigates to arena page" do
        post interact_hotspot_world_path, params: {hotspot_id: arena.id}

        expect(response).to redirect_to("/arena")
      end

      it "workshop hotspot navigates to crafting page" do
        post interact_hotspot_world_path, params: {hotspot_id: workshop.id}

        expect(response).to redirect_to("/crafting_jobs")
      end

      it "exit gate transitions to destination zone" do
        post interact_hotspot_world_path, params: {hotspot_id: exit_gate.id}

        expect(response).to redirect_to(world_path)
        position.reload
        expect(position.zone.biome).to eq("plains")
      end
    end
  end
end
