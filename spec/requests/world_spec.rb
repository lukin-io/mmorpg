# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World", type: :request do
  def world_action_offer_for(character:, position:, action_type:, target:)
    create(
      :world_action_offer,
      character:,
      zone: position.zone,
      x: position.x,
      y: position.y,
      action_type: action_type.to_s,
      target:
    )
  end

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
    let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before do
      sign_in user, scope: :user
      create_explicit_tiles(zone, x_range: 3..7, y_range: 3..7)
    end

    context "when character has a position" do
      it "renders the world view successfully" do
        get world_path
        expect(response).to have_http_status(:success)
      end

      it "displays the zone name" do
        get world_path
        expect(response.body).to include("Окрестность Форпоста")
      end

      it "displays the player coordinates" do
        get world_path
        expect(response.body).to include("5")
      end

      it "uses the persisted position as the resume entry state" do
        get world_path

        expect(response.body).to include('data-nl-world-map-player-x-value="5"')
        expect(response.body).to include('data-nl-world-map-player-y-value="5"')
        expect(response.body).to include("[5, 5]")
      end

      it "resumes active travel from the movement command without changing coordinates early" do
        create(
          :movement_command,
          :moving,
          character: character,
          zone: zone,
          direction: "north",
          from_x: 5,
          from_y: 5,
          target_x: 5,
          target_y: 4,
          ends_at: 20.seconds.from_now
        )

        get world_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-nl-world-map-movement-active-value="true"')
        expect(response.body).to include('data-nl-world-map-player-x-value="5"')
        expect(response.body).to include('data-nl-world-map-player-y-value="5"')
        position.reload
        expect([position.x, position.y]).to eq([5, 5])
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
          name: "Форпост",
          location_type: "city",
          width: 15,
          height: 15,
          metadata: {"description" => "Форпост"})
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
        expect(response.body).to include("Форпост")
      end
    end

    context "when character has no position" do
      before { position.destroy }

      it "creates a default position and renders successfully" do
        starter_zone = create(:zone, location_type: "city", name: "Форпост")
        create(:spawn_point, zone: starter_zone, x: 3, y: 4, default_entry: true)

        get world_path

        expect(response).to have_http_status(:success)
        expect(character.reload.position).to be_present
        expect(character.position.x).to eq(3)
        expect(character.position.y).to eq(4)
      end
    end
  end

  describe "POST /world/move" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before do
      sign_in user, scope: :user
    end

    def movement_offer(direction)
      state = Game::Movement::MapState.new(character: character).call
      destination = state.destinations.find { |offer| offer.direction == direction.to_s }
      raise "missing #{direction} offer" unless destination

      MovementCommand.offered.find(destination.id)
    end

    def post_offer(command, headers: {})
      post move_world_path,
        params: {
          direction: command.direction,
          target_x: command.target_x,
          target_y: command.target_y,
          action_key: command.action_key
        },
        headers: headers
    end

    context "with valid movement offer" do
      it "starts timed travel without changing coordinates immediately" do
        command = movement_offer(:north)

        post_offer(command)

        expect(response).to redirect_to(world_path)
        expect(position.reload.x).to eq(5)
        expect(position.y).to eq(5)

        moving_command = MovementCommand.moving.last
        expect(moving_command.direction).to eq("north")
        expect(moving_command.target_position).to eq([5, 4])
        expect(moving_command.ends_at).to be > moving_command.started_at
      end

      it "redirects to world path with moving notice on HTML format" do
        post_offer(movement_offer(:east))

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Переход начат.")
      end

      it "returns turbo stream movement state" do
        post_offer(movement_offer(:north), headers: {"Accept" => "text/vnd.turbo-stream.html"})

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include('action="update"')
        expect(response.body).not_to include('action="replace"')
        expect(response.body).to include('target="game-map"')
        expect(response.body).to include('target="location-info"')
        expect(response.body).to include('target="available-actions"')
        expect(response.body).to include("nl-map-container")
        expect(response.body).to include("movement-form")
        expect(response.body).to include("data-nl-world-map-movement-active-value=\"true\"")
        expect(response.body).to include("data-nl-world-map-player-y-value=\"5\"")
      end

      it "finalizes coordinates when the travel timer has elapsed" do
        post_offer(movement_offer(:north))
        command = MovementCommand.moving.last
        command.update!(ends_at: 1.second.ago)

        get world_path

        expect(response).to have_http_status(:success)
        expect(position.reload.x).to eq(5)
        expect(position.y).to eq(4)
        expect(command.reload).to be_completed
      end

      it "prevents a second movement while travel is active" do
        post_offer(movement_offer(:north))

        post move_world_path, params: {direction: "east"}

        expect(response).to redirect_to(world_path)
        expect(MovementCommand.moving.count).to eq(1)
        expect(position.reload.y).to eq(5)
      end

      it "marks the accepted action offer as moving and cancels sibling offers on refresh" do
        command = movement_offer(:north)
        sibling = MovementCommand.offered.where(character: character).where.not(id: command.id).first

        post_offer(command)
        get world_path

        expect(command.reload).to be_moving
        expect(sibling.reload).to be_cancelled
      end
    end

    context "with invalid movement" do
      it "rejects movement without a valid action key" do
        post move_world_path, params: {direction: "north", target_x: 5, target_y: 4, action_key: "bad-key"}

        expect(response).to redirect_to(world_path)
        expect(MovementCommand.moving).to be_empty
        expect(position.reload.y).to eq(5)
      end

      it "rejects a target that does not match the offered action key" do
        command = movement_offer(:north)

        post move_world_path,
          params: {
            direction: command.direction,
            target_x: command.target_x + 2,
            target_y: command.target_y,
            action_key: command.action_key
          }

        expect(response).to redirect_to(world_path)
        expect(MovementCommand.moving).to be_empty
        expect(position.reload.y).to eq(5)
      end

      it "prevents moving outside zone boundaries" do
        position.update!(y: 0)

        post move_world_path, params: {direction: "north"}

        expect(response).to redirect_to(world_path)
        expect(MovementCommand.moving).to be_empty
        expect(position.reload.y).to eq(0)
      end

      it "returns turbo stream error and restores map state" do
        post move_world_path,
          params: {direction: "north", target_x: 5, target_y: 4, action_key: "bad-key"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('target="flash"')
        expect(response.body).to include('target="game-map"')
        expect(response.body).to include('target="available-actions"')
      end
    end
  end

  describe "POST /world/enter" do
    let(:user) { create(:user) }
    let(:outdoor_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
    let(:city_zone) { create(:zone, name: "Форпост", location_type: "city", width: 10, height: 10) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: outdoor_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: city_zone, x: 3, y: 3, default_entry: true) }

    before { sign_in user, scope: :user }

    context "with valid location" do
      it "moves character to the new zone" do
        post enter_world_path, params: {location_key: city_zone.name}

        position.reload
        expect(position.zone).to eq(city_zone)
        expect(position.x).to eq(3)
        expect(position.y).to eq(3)
      end

      it "redirects with success notice" do
        post enter_world_path, params: {location_key: city_zone.name}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Entered").or include("Форпост")
      end
    end

    context "with invalid location" do
      it "returns alert for non-existent location" do
        post enter_world_path, params: {location_key: "nonexistent"}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("не найдена")
      end
    end
  end

  describe "POST /world/exit" do
    let(:user) { create(:user) }
    let(:city_zone) do
      create(:zone,
        name: "Форпост",
        location_type: "city",
        width: 10,
        height: 10,
        metadata: {"exit_to" => "Окрестность Форпоста"})
    end
    let(:outdoor_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
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
      expect(response.body).to include("Exited").or include("Окрестность Форпоста")
    end
  end

  describe "map rendering" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Test Zone", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before do
      sign_in user, scope: :user
      create_explicit_tiles(zone, x_range: 8..12, y_range: 8..12)
    end

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

    it "uses explicit tile terrain classes" do
      get world_path

      expect(response.body).to include("nl-tile-bg--outdoor")
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

  describe "outdoor terrain rendering" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Mixed Zone", location_type: "outdoor", width: 50, height: 50) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 25, y: 25) }

    before do
      sign_in user, scope: :user
      create_explicit_tiles(zone, x_range: 23..27, y_range: 23..27)
    end

    it "renders map with tile coordinates" do
      get world_path

      # Verify the map contains tiles with coordinate data
      expect(response.body).to include('data-x="25"')
      expect(response.body).to include('data-y="25"')
    end

    it "renders map with terrain data" do
      get world_path

      # Verify terrain types are rendered
      expect(response.body).to include('data-terrain="outdoor"')
    end

    it "renders outdoor terrain classes" do
      get world_path

      expect(response.body).to match(/nl-tile-bg--outdoor/)
    end
  end

  # Tests for add_live_tile_features logic
  describe "map tile feature display" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Feature Test Zone", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before do
      sign_in user, scope: :user
      create_explicit_tiles(zone, x_range: 8..12, y_range: 8..12)
    end

    describe "TileNpc display" do
      context "when database TileNpc exists and is alive" do
        let(:npc_template) { create(:npc_template, name: "Чумная крыса", npc_key: "plague_rat_visible") }
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

          expect(response.body).to include("Чумная крыса")
        end

        it "shows NPC marker" do
          get world_path

          expect(response.body).to include("nl-tile-npc")
        end
      end

      context "when database TileNpc exists but is dead (defeated)" do
        let(:npc_template) { create(:npc_template, name: "Побежденная крыса", npc_key: "plague_rat_defeated") }
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

          expect(response.body).not_to include("Побежденная крыса")
        end

        it "hides NPC until respawn time passes" do
          get world_path

          # The defeated NPC tile should not have NPC marker
          expect(response.body).not_to include('title="Побежденная крыса"')
        end
      end

      context "when database TileNpc is alive" do
        let(:npc_template) { create(:npc_template, name: "Живая крыса", npc_key: "plague_rat_alive") }
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

          expect(response.body).to include("Живая крыса")
        end
      end
    end
  end

  describe "authentication requirements" do
    let(:zone) { create(:zone, name: "Auth Zone", location_type: "outdoor") }

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
    let(:source_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city", width: 10, height: 10) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: source_zone, x: 5, y: 5) }
    let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 3, y: 3, default_entry: true) }

    before { sign_in user, scope: :user }

    def building_entry_params(building)
      {
        building_id: building.id,
        action_key: world_action_offer_for(
          character: character,
          position: position,
          action_type: :enter_building,
          target: building
        ).action_key
      }
    end

    def post_building_entry(building, headers: {})
      post enter_building_world_path,
        params: building_entry_params(building),
        headers:
    end

    # -------------------------------------------------------------------------
    # Success Cases
    # -------------------------------------------------------------------------
    context "with valid building at current position" do
      let!(:building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "outpost_gate",
          name: "Ворота Форпоста",
          building_type: "city",
          destination_zone: destination_zone,
          destination_x: 7,
          destination_y: 7,
          required_level: 1,
          active: true)
      end

      it "moves character to destination zone" do
        post_building_entry(building)

        position.reload
        expect(position.zone).to eq(destination_zone)
      end

      it "moves character to specified destination coordinates" do
        post_building_entry(building)

        position.reload
        expect(position.x).to eq(7)
        expect(position.y).to eq(7)
      end

      it "redirects to world path with success notice on HTML format" do
        post_building_entry(building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Ворота Форпоста").or include("enter")
      end

      it "redirects on turbo stream format to trigger full page reload" do
        post_building_entry(building, headers: {"Accept" => "text/vnd.turbo-stream.html"})

        # After entering a building, we redirect because:
        # 1. Target zone might be a city which requires city_view.html.erb (not partials)
        # 2. Redirect with see_other status triggers Turbo to do full page navigation
        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(world_path)
      end

      it "completes the accepted building entry offer on success" do
        offer = world_action_offer_for(
          character: character,
          position: position,
          action_type: :enter_building,
          target: building
        )

        post enter_building_world_path,
          params: {building_id: building.id, action_key: offer.action_key}

        expect(offer.reload).to be_completed
      end

      it "rejects entry without a live action offer" do
        post enter_building_world_path, params: {building_id: building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Action offer")
        expect(position.reload.zone).to eq(source_zone)
      end
    end

    context "with building using default spawn point" do
      let!(:building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "spawn_test_city_gate",
          name: "Spawn Test Gate",
          destination_zone: destination_zone,
          destination_x: nil,
          destination_y: nil,
          required_level: 1,
          active: true)
      end

      it "uses destination zone spawn point when no specific coordinates" do
        post_building_entry(building)

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
        expect(response.body).to include("Здание не найдено.")
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
          building_key: "distant_city_gate",
          name: "Distant City Gate",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns alert when not at building location" do
        post_building_entry(distant_building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("На этой клетке нет здания.")
      end

      it "does not move character" do
        post_building_entry(distant_building)

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
          building_key: "inactive_city_gate",
          name: "Inactive City Gate",
          destination_zone: destination_zone,
          required_level: 1,
          active: false)
      end

      it "returns alert for inactive building" do
        post_building_entry(inactive_building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Здание сейчас недоступно.")
      end

      it "does not move character" do
        offer = world_action_offer_for(
          character: character,
          position: position,
          action_type: :enter_building,
          target: inactive_building
        )

        post enter_building_world_path,
          params: {building_id: inactive_building.id, action_key: offer.action_key}

        position.reload
        expect(position.zone).to eq(source_zone)
        expect(offer.reload).to be_failed
      end
    end

    context "when character level is too low" do
      let!(:high_level_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "high_level_city_gate",
          name: "High Level City Gate",
          destination_zone: destination_zone,
          required_level: 50,
          active: true)
      end

      it "returns alert with level requirement" do
        post_building_entry(high_level_building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("уровень 50")
      end

      it "does not move character" do
        post_building_entry(high_level_building)

        position.reload
        expect(position.zone).to eq(source_zone)
      end

      it "returns turbo stream error with level requirement" do
        post_building_entry(high_level_building, headers: {"Accept" => "text/vnd.turbo-stream.html"})

        expect(response.body).to include("turbo-stream")
      end
    end

    context "when building has no destination zone" do
      let!(:no_dest_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "no_dest_city_gate",
          name: "No Destination City Gate",
          destination_zone: nil,
          required_level: 1,
          active: true)
      end

      it "returns alert for inaccessible building" do
        post_building_entry(no_dest_building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Здание сейчас недоступно.")
      end

      it "does not move character" do
        post_building_entry(no_dest_building)

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
        expect(response.body).to include("Здание не найдено.")
      end
    end

    context "when building_id is empty string" do
      it "returns alert for missing building" do
        post enter_building_world_path, params: {building_id: ""}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Здание не найдено.")
      end
    end

    context "when no building_id parameter" do
      it "returns alert for missing building" do
        post enter_building_world_path

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Здание не найдено.")
      end
    end

    context "when building is in different zone" do
      let(:other_zone) { create(:zone, name: "Other Zone", location_type: "outdoor") }
      let!(:other_zone_building) do
        create(:tile_building,
          zone: other_zone.name,
          x: 5,
          y: 5,
          building_key: "other_zone_city_gate",
          name: "Other Zone City Gate",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns alert when building is in different zone" do
        post_building_entry(other_zone_building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("На этой клетке нет здания.")
      end
    end
  end

  describe "TileBuilding display on map" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Building Display Zone", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Destination", location_type: "city") }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before { sign_in user, scope: :user }

    context "when active building exists at adjacent tile" do
      let!(:building) do
        create(:tile_building,
          zone: zone.name,
          x: 11, # Adjacent tile (east)
          y: 10,
          building_key: "map_test_city_gate",
          name: "Map Test City Gate",
          building_type: "city",
          icon: "🏙️",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows building marker on map" do
        get world_path

        expect(response.body).to include("nl-tile-building")
      end

      it "shows building icon on map" do
        get world_path

        expect(response.body).to include("🏙️")
      end

      it "shows building name in title attribute" do
        get world_path

        expect(response.body).to include("Map Test City Gate")
      end
    end

    context "when building is at current position" do
      let!(:building_at_position) do
        create(:tile_building,
          zone: zone.name,
          x: 10,
          y: 10,
          building_key: "current_position_city_gate",
          name: "Current Position City Gate",
          building_type: "city",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows building in actions panel" do
        get world_path

        expect(response.body).to include("Current Position City Gate")
        expect(response.body).to include("Войти")
      end
    end

    context "when building is inactive" do
      let!(:inactive_building) do
        create(:tile_building,
          zone: zone.name,
          x: 11,
          y: 10,
          building_key: "inactive_map_city_gate",
          name: "Inactive Map City Gate",
          destination_zone: destination_zone,
          active: false)
      end

      it "does not show inactive building on map" do
        get world_path

        expect(response.body).not_to include("Inactive Map City Gate")
      end
    end

    context "with different building types" do
      let!(:shop) do
        create(:tile_building,
          zone: zone.name,
          x: 9,
          y: 10,
          building_key: "test_shop",
          name: "Лавка",
          building_type: "shop",
          icon: "🏪",
          destination_zone: destination_zone,
          active: true)
      end

      let!(:arena) do
        create(:tile_building,
          zone: zone.name,
          x: 10,
          y: 9,
          building_key: "test_arena",
          name: "Arena",
          building_type: "arena",
          icon: "⚔️",
          destination_zone: destination_zone,
          active: true)
      end

      it "shows documented icons for different building types" do
        get world_path

        expect(response.body).to include("🏪")
        expect(response.body).to include("⚔️")
      end
    end
  end

  describe "TileBuilding actions panel display" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Actions Panel Zone", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Actions Destination", location_type: "city") }
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

        expect(response.body).to include("Войти")
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

        expect(response.body).to include("уровень 20")
        expect(response.body).to include("building-blocked")
      end
    end
  end

  describe "authentication requirements for enter_building" do
    let(:zone) { create(:zone, name: "Auth Building Zone", location_type: "outdoor") }
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
  # Bug: Feature hotspots such as Arena weren't navigating properly
  #      because only enter_zone had proper respond_to block with status: :see_other
  # Fix: Added proper respond_to block for open_feature hotspots

  describe "POST /world/interact_hotspot" do
    let(:user) { create(:user) }
    let(:city_zone) { create(:zone, name: "Hotspot Test City", location_type: "city", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor", width: 20, height: 20) }
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

          expect(flash[:notice]).to include("Вход")
        end
      end
    end

    context "with implemented shop hotspot" do
      let!(:shop_hotspot) do
        create(:city_hotspot, :shop,
          zone: city_zone,
          required_level: 1,
          active: true)
      end

      it "redirects to the shop on HTML" do
        post interact_hotspot_world_path, params: {hotspot_id: shop_hotspot.id}

        expect(response).to redirect_to("/shop")
        expect(flash[:notice]).to include("Лавка")
      end

      it "returns a turbo redirect to the shop" do
        post interact_hotspot_world_path,
          params: {hotspot_id: shop_hotspot.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to("/shop")
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
        expect(response.body).to include("не найдена")
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
        expect(response.body).to include("уровень 50")
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
        expect(response.body).to include("недоступна")
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
      let(:other_zone) { create(:zone, name: "Other City", location_type: "city") }
      let!(:other_hotspot) do
        create(:city_hotspot, :arena, zone: other_zone, active: true)
      end

      it "returns failure when hotspot zone doesn't match character zone" do
        post interact_hotspot_world_path, params: {hotspot_id: other_hotspot.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("не найдена")
      end
    end
  end

  # ============================================
  # Integration: City View with Hotspots
  # ============================================
  # Integration tests for the full city view flow

  describe "city view integration" do
    let(:user) { create(:user) }
    let(:city_zone) { create(:zone, name: "Integration Test City", location_type: "city", width: 20, height: 20) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: city_zone, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    context "with multiple hotspots" do
      let!(:arena) { create(:city_hotspot, :arena, zone: city_zone, active: true, required_level: 1) }
      let!(:shop) { create(:city_hotspot, :shop, zone: city_zone, active: true, required_level: 1) }
      let!(:exit_gate) do
        dest = create(:zone, name: "Exit Dest", location_type: "outdoor")
        create(:spawn_point, zone: dest, default_entry: true)
        create(:city_hotspot, :city_gate, zone: city_zone, destination_zone: dest, active: true)
      end
      it "renders city view with all active hotspots" do
        get world_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Arena")
        expect(response.body).to include("Лавка")
        expect(response.body).to include("Ворота Форпоста")
      end

      it "includes form for each interactive hotspot" do
        get world_path

        expect(response.body).to include("interact_hotspot")
        expect(response.body).to include(arena.id.to_s)
        expect(response.body).to include(shop.id.to_s)
      end

      it "arena hotspot navigates to arena page" do
        post interact_hotspot_world_path, params: {hotspot_id: arena.id}

        expect(response).to redirect_to("/arena")
      end

      it "shop hotspot navigates to the shop page" do
        post interact_hotspot_world_path, params: {hotspot_id: shop.id}

        expect(response).to redirect_to("/shop")
        expect(flash[:notice]).to include("Лавка")
      end

      it "exit gate transitions to destination zone" do
        post interact_hotspot_world_path, params: {hotspot_id: exit_gate.id}

        expect(response).to redirect_to(world_path)
        position.reload
        expect(position.zone.location_type).to eq("outdoor")
      end
    end
  end
end
