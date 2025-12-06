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

    before { sign_in user }

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

    before { sign_in user }

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
    let(:city_zone) { create(:zone, name: "Capital", biome: "city", slug: "capital", width: 10, height: 10) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: outdoor_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: city_zone, x: 3, y: 3, default_entry: true) }

    before { sign_in user }

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

    before { sign_in user }

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

    before { sign_in user }

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

    before { sign_in user }

    it "generates deterministic terrain based on coordinates" do
      get world_path
      first_response = response.body

      get world_path
      second_response = response.body

      # Same coordinates should yield same terrain
      expect(first_response).to eq(second_response)
    end
  end

  describe "JSON API responses" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "API Zone", biome: "plains", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5, last_action_at: 10.seconds.ago) }

    before { sign_in user }

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
    let!(:inventory) { create(:inventory, character: character, slot_capacity: 20, weight_capacity: 100, current_weight: 0) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before { sign_in user }

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

        expect(response.body).to include('target="flash-messages"')
      end
    end

    # Regression test: Depleted resources should not show on map
    context "when resource is depleted" do
      let!(:depleted_resource) do
        create(:tile_resource,
          zone: zone.name,
          x: position.x,
          y: position.y,
          resource_key: "test_ore",
          resource_type: "ore",
          quantity: 0,
          base_quantity: 1,
          respawns_at: 30.minutes.from_now)
      end

      it "does not include depleted resource in map" do
        get world_path

        # Depleted resources should not show resource markers
        expect(response.body).not_to include('data-resource="Test Ore"')
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
end
