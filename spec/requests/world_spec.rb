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

  def city_hotspot_action_params(character:, position:, hotspot:)
    offer = create(
      :world_action_offer,
      character:,
      zone: position.zone,
      x: position.x,
      y: position.y,
      action_type: hotspot.world_action_type,
      target: hotspot
    )
    {hotspot_id: hotspot.id, action_key: offer.action_key}
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
    let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
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


      it "uses the compact Neverlands game shell for the playable world" do
        get world_path

        expect(response.body).to include('<body class="nl-game-layout"')
        expect(response.body).to include("nl-top-bar")
        expect(response.body).to include("nl-bottom-bar")
      end

      it "displays the zone name" do
        get world_path
        expect(response.body).to include("Outpost Surroundings")
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
        expect(response.body).to include('data-nl-world-map-movement-delta-x-value="0"')
        expect(response.body).to include('data-nl-world-map-movement-delta-y-value="-1"')
        expect(response.body).to match(/data-nl-world-map-movement-total-seconds-value="\d+"/)
        position.reload
        expect([position.x, position.y]).to eq([5, 5])
      end

      it "renders the map partial" do
        get world_path
        expect(response.body).to include("nl-map-container")
      end

      it "renders the fatigue lock and withholds movement offers at 86 percent" do
        character.update!(fatigue_percent: 86, fatigue_updated_at: Time.current)

        get world_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Move, Look, and Enter are unavailable")
        expect(response.body).not_to include("nl-tile-clickable--available")
        expect(MovementCommand.offered.where(character:)).to be_empty
      end


      it "renders the captured fifteen-by-nine buffer around a thirteen-by-seven viewport" do
        get world_path

        document = Nokogiri::HTML(response.body)
        expect(document.css(".nl-map-tile").size).to eq(135)
        expect(response.body).to include("world/forpost-terrain", "background-size: 1000px 1000px")
        expect(response.body).not_to include("neverlands_outskirts")
      end

      it "renders an exact configured cell-art slice and the regional fallback together" do
        authored_tile = MapTileTemplate.find_by!(zone: zone.name, x: 4, y: 5)
        authored_tile.update!(
          metadata: {
            "source_map" => "m_1001_999",
            "cell_art" => {"key" => "forpost_terrain", "column" => 7, "row" => 7}
          }
        )

        get world_path

        document = Nokogiri::HTML(response.body)
        authored_cell = document.at_css("#tile_4_5")
        fallback_cell = document.at_css("#tile_5_5")
        expect(authored_cell["data-cell-art-key"]).to eq("forpost_terrain")
        expect(authored_cell["style"]).to include(
          "background-position: -700px -700px",
          "background-size: 1000px 1000px"
        )
        expect(fallback_cell["data-cell-art-key"]).to eq("")
        expect(fallback_cell["style"]).to include("world/forpost-terrain", "background-image", "background-size: 1000px 1000px")
      end

      it "uses the regional fallback for malformed legacy cell-art metadata" do
        legacy_tile = MapTileTemplate.find_by!(zone: zone.name, x: 4, y: 5)
        legacy_tile.update_column(
          :metadata,
          {"source_map" => "m_legacy", "cell_art" => {"key" => "missing_art", "column" => 0, "row" => 0}}
        )

        get world_path

        cell = Nokogiri::HTML(response.body).at_css("#tile_4_5")
        expect(cell["data-cell-art-key"]).to eq("")
        expect(cell["style"]).to include("world/forpost-terrain", "background-image", "background-size: 1000px 1000px")
      end


      it "keeps the cursor centered at an outdoor region boundary" do
        position.update!(x: 0, y: 0)

        get world_path

        document = Nokogiri::HTML(response.body)
        expect(document.css(".nl-map-tile").size).to eq(135)
        expect(document.css(".nl-map-tile--outside")).not_to be_empty
        expect(response.body).to include('id="tile_-7_-4"')
        expect(response.body).to include('style="left: 600px; top: 300px;"')
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
          name: "Outpost",
          location_type: "city",
          width: 15,
          height: 15,
          metadata: {"description" => "Outpost"})
      end

      before do
        position.update!(zone: city_zone)
      end

      it "renders the city view" do
        get world_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("city-view-container")
      end

      it "includes the city description from metadata" do
        get world_path
        expect(response.body).to include("Outpost")
      end
    end

    context "when character has no position" do
      before { position.destroy }

      it "creates a default position and renders successfully" do
        starter_zone = create(:zone, location_type: "city", name: "Outpost")
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
    let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
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
      it "lets a same-cell hostile NPC interrupt movement before travel starts" do
        create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)
        command = movement_offer(:north)

        expect { post_offer(command) }.to change(ArenaMatch, :count).by(1)

        expect(response).to redirect_to(arena_match_path(ArenaMatch.last))
        expect(command.reload).to be_offered
        expect(position.reload).to have_attributes(x: 5, y: 5)
      end

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

      it "uses the persisted Wanderer level for the offered and accepted travel duration" do
        character.update!(passive_skills: attributes_for(:character, :master_wanderer).fetch(:passive_skills))
        command = movement_offer(:north)

        expect(command.travel_seconds).to eq(24)
        character.update!(passive_skills: {})

        post_offer(command)

        moving_command = command.reload
        expect(moving_command).to be_moving
        expect(moving_command.ends_at - moving_command.started_at).to eq(24.seconds)
      end

      it "redirects to world path with moving notice on HTML format" do
        post_offer(movement_offer(:east))

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Move started.")
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

  describe "map rendering" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Test Zone", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 10, y: 10) }

    before do
      sign_in user, scope: :user
      create_explicit_tiles(zone, x_range: 8..12, y_range: 8..12)
    end

    it "renders a fifteen-by-nine buffer around the player" do
      get world_path

      expect(response.body).to include("tile_3_6").or include("data-x=\"3\"")
      expect(response.body).to include("tile_17_14").or include("data-x=\"17\"")
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

    describe "hidden TileNpc encounter state" do
      context "when database TileNpc exists and is alive" do
        let(:npc_template) { create(:npc_template, name: "Plague Rat", npc_key: "plague_rat_visible") }
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

        it "does not reveal the database NPC on the map" do
          get world_path

          expect(response.body).not_to include("Plague Rat")
        end

        it "does not render an NPC marker" do
          get world_path

          expect(response.body).not_to include("nl-tile-npc")
        end
      end

      context "when database TileNpc exists but is dead (defeated)" do
        let(:npc_template) { create(:npc_template, name: "Defeated Rat", npc_key: "plague_rat_defeated") }
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

          expect(response.body).not_to include("Defeated Rat")
        end

        it "hides NPC until respawn time passes" do
          get world_path

          # The defeated NPC tile should not have NPC marker
          expect(response.body).not_to include('title="Defeated Rat"')
        end
      end

      context "when database TileNpc is alive" do
        let(:npc_template) { create(:npc_template, name: "Live Rat", npc_key: "plague_rat_alive") }
        let!(:alive_npc) do
          create(:tile_npc,
            zone: zone.name,
            x: 9, # Adjacent tile (west)
            y: 10,
            npc_template: npc_template,
            defeated_at: nil,
            respawns_at: nil)
        end

        it "keeps the alive NPC hidden on the map" do
          get world_path

          expect(response.body).not_to include("Live Rat")
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

  describe "POST /world/perform_local_action" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Local Action Zone", location_type: "outdoor", width: 1000, height: 1000) }
    let(:character) { create(:character, user:, level: 4, current_hp: 100, max_hp: 100) }
    let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
    let!(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    def local_action_offer(owner: character, at: position, target: tile, **attributes)
      create(
        :world_action_offer,
        :resource_search,
        character: owner,
        zone: at.zone,
        x: at.x,
        y: at.y,
        target:,
        **attributes
      )
    end

    def post_local_action(offer, params: {}, headers: {})
      post perform_local_action_world_path,
        params: {
          tile_id: tile.id,
          local_action_type: "resource_search",
          action_key: offer.action_key
        }.merge(params),
        headers:
    end

    it "renders the server-offered resource action on the current cell" do
      get world_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Look Around")
      expect(response.body).to include("Search for herbs and local resources")
      expect(response.body).to include('name="action_key"')
    end

    it "completes an uninterrupted resource-search offer without awarding invented resources" do
      offer = local_action_offer

      expect { post_local_action(offer) }.not_to change(InventoryItem, :count)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_completed
      follow_redirect!
      expect(response.body).to include("search the surroundings")
    end

    it "returns a Turbo redirect after a successful local action" do
      offer = local_action_offer

      post_local_action(offer, headers: {"Accept" => "text/vnd.turbo-stream.html"})

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(world_path)
    end

    it "hands a resource action off to shared combat when a hostile NPC interrupts" do
      npc_template = create(
        :npc_template,
        npc_key: "resource_ambush_rat",
        name: "Plague Rat",
        role: "hostile",
        metadata: {"health" => 40, "base_damage" => 4}
      )
      create(
        :tile_npc,
        npc_template:,
        zone: zone.name,
        x: 5,
        y: 5,
        current_hp: 40,
        max_hp: 40
      )
      offer = local_action_offer

      expect { post_local_action(offer) }.to change(ArenaMatch, :count).by(1)

      expect(response).to redirect_to(arena_match_path(ArenaMatch.last))
      expect(ArenaMatch.last.metadata["source"]).to eq("world_npc")
      expect(offer.reload).to be_completed
    end

    it "rolls the offer back when hostile combat startup fails" do
      npc_template = create(
        :npc_template,
        npc_key: "failed_resource_ambush_rat",
        name: "Failed Ambush Rat",
        role: "hostile",
        metadata: {"health" => 40, "base_damage" => 4}
      )
      create(
        :tile_npc,
        npc_template:,
        zone: zone.name,
        x: 5,
        y: 5,
        current_hp: 40,
        max_hp: 40
      )
      offer = local_action_offer
      allow_any_instance_of(Game::World::StartNpcFight).to receive(:call)
        .and_raise(Game::World::StartNpcFight::FightViolationError, "Combat startup failed.")

      expect { post_local_action(offer) }.not_to change(ArenaMatch, :count)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "rejects a missing tile" do
      offer = local_action_offer

      post_local_action(offer, params: {tile_id: nil})

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "rejects a null local action type" do
      offer = local_action_offer

      post_local_action(offer, params: {local_action_type: nil})

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "rejects an expired action offer" do
      offer = local_action_offer(expires_at: 1.second.ago)

      post_local_action(offer)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "rejects an offer for a different local action type" do
      offer = local_action_offer(action_type: "fish")

      post_local_action(offer)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "fails an accepted offer when the authored action becomes inactive" do
      offer = local_action_offer
      tile.update!(
        metadata: {
          "local_actions" => [
            {"type" => "resource_search", "source_id" => "look", "active" => false}
          ]
        }
      )

      expect { post_local_action(offer) }.not_to change(InventoryItem, :count)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_failed
    end

    it "rejects an offer after the character changes cells" do
      offer = local_action_offer
      position.update!(x: 6)

      post_local_action(offer)

      expect(response).to redirect_to(world_path)
      expect(offer.reload).to be_offered
    end

    it "forbids another user's action offer" do
      other_user = create(:user)
      other_character = create(:character, user: other_user)
      other_position = create(:character_position, character: other_character, zone:, x: 5, y: 5)
      offer = local_action_offer(owner: other_character, at: other_position)

      post_local_action(offer)

      expect(response).to redirect_to(root_path)
      expect(offer.reload).to be_offered
    end

    it "requires authentication" do
      offer = local_action_offer
      sign_out user

      post_local_action(offer)

      expect(response).to redirect_to(new_user_session_path)
      expect(offer.reload).to be_offered
    end
  end

  # ===========================================================================
  # TileBuilding Tests
  # ===========================================================================
  describe "POST /world/enter_building" do
    let(:user) { create(:user) }
    let(:source_zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city", width: 10, height: 10) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: source_zone, x: 5, y: 5) }
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
          name: "Outpost Gate",
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
        expect(response.body).to include("Outpost Gate").or include("enter")
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

      it "lets a same-cell hostile NPC interrupt entry without moving the character" do
        create(:tile_npc, :multi_npc_encounter, zone: source_zone.name, x: 5, y: 5)
        offer = world_action_offer_for(
          character: character,
          position: position,
          action_type: :enter_building,
          target: building
        )

        expect {
          post enter_building_world_path,
            params: {building_id: building.id, action_key: offer.action_key}
        }.to change(ArenaMatch, :count).by(1)

        expect(response).to redirect_to(arena_match_path(ArenaMatch.last))
        expect(position.reload).to have_attributes(zone: source_zone, x: 5, y: 5)
        expect(offer.reload).to be_completed
      end

      it "rejects entry without a live action offer" do
        post enter_building_world_path, params: {building_id: building.id}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Action offer")
        expect(position.reload.zone).to eq(source_zone)
      end

      it "forbids another user's building-entry offer" do
        other_user = create(:user)
        other_character = create(:character, user: other_user)
        other_position = create(:character_position, character: other_character, zone: source_zone, x: 5, y: 5)
        offer = world_action_offer_for(
          character: other_character,
          position: other_position,
          action_type: :enter_building,
          target: building
        )

        post enter_building_world_path,
          params: {building_id: building.id, action_key: offer.action_key}

        expect(response).to redirect_to(root_path)
        expect(position.reload.zone).to eq(source_zone)
        expect(offer.reload).to be_offered
      end
    end

    context "with an entrance missing authored destination coordinates" do
      let!(:building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 5,
          y: 5,
          building_key: "unconfigured_city_gate",
          name: "Unconfigured City Gate",
          destination_zone: destination_zone,
          destination_x: nil,
          destination_y: nil,
          required_level: 1,
          active: true)
      end

      it "does not infer coordinates from a spawn point" do
        post_building_entry(building)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Entrance is currently unavailable.")
        expect(position.reload).to have_attributes(zone: source_zone, x: 5, y: 5)
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
        expect(response.body).to include("Building not found.")
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
        expect(response.body).to include("There is no city entrance on this cell.")
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
        expect(response.body).to include("Entrance is currently unavailable.")
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
        expect(response.body).to include("Entrance is currently unavailable.")
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
        expect(response.body).to include("Building not found.")
      end
    end

    context "when building_id is empty string" do
      it "returns alert for missing building" do
        post enter_building_world_path, params: {building_id: ""}

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Building not found.")
      end
    end

    context "when no building_id parameter" do
      it "returns alert for missing building" do
        post enter_building_world_path

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("Building not found.")
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
        expect(response.body).to include("There is no city entrance on this cell.")
      end
    end
  end

  describe "TileBuilding display on map" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city") }
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
          name: "West Gate",
          building_type: "city",
          destination_zone: destination_zone,
          destination_x: 0,
          destination_y: 0,
          active: true)
      end

      it "shows building marker on map" do
        get world_path

        expect(response.body).to include("nl-tile-building")
      end

      it "uses a compact text label instead of generic emoji artwork" do
        get world_path

        expect(response.body).to include("nl-entity-label")
        expect(response.body).not_to include("🏙️")
      end

      it "shows building name in title attribute" do
        get world_path

        expect(response.body).to include("West Gate")
      end
    end

    context "when building is at current position" do
      let!(:building_at_position) do
        create(:tile_building,
          zone: zone.name,
          x: 10,
          y: 10,
          building_key: "current_position_city_gate",
          name: "West Gate",
          building_type: "city",
          destination_zone: destination_zone,
          destination_x: 0,
          destination_y: 0,
          active: true)
      end

      it "shows building in actions panel" do
        get world_path

        expect(response.body).to include("West Gate")
        expect(response.body).to include("Enter")
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
  end

  describe "TileBuilding actions panel display" do
    let(:user) { create(:user) }
    let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
    let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city") }
    let(:character) { create(:character, user: user, level: 5) }
    let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

    before { sign_in user, scope: :user }

    context "when character can enter building" do
      let!(:enterable_building) do
        create(:tile_building,
          zone: zone.name,
          x: 5,
          y: 5,
          building_key: "west_gate_action",
          name: "West Gate",
          destination_zone: destination_zone,
          destination_x: 0,
          destination_y: 0,
          required_level: 1,
          active: true,
          metadata: {"description" => "Enter Forpost through the West Gate."})
      end

      it "shows enter button" do
        get world_path

        expect(response.body).to include("Enter")
      end

      it "shows building description" do
        get world_path

        expect(response.body).to include("Enter Forpost through the West Gate.")
      end

      it "shows destination zone name" do
        get world_path

        expect(response.body).to include("Outpost")
      end
    end

    context "when the entrance lacks authored destination coordinates" do
      let!(:blocked_building) do
        create(:tile_building,
          zone: zone.name,
          x: 5,
          y: 5,
          building_key: "unconfigured_gate",
          name: "Unconfigured Gate",
          destination_zone: destination_zone,
          destination_x: nil,
          destination_y: nil,
          active: true)
      end

      it "shows blocked reason instead of enter button" do
        get world_path

        expect(response.body).to include("Entrance is currently unavailable.")
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
    let(:destination_zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor", width: 20, height: 20) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:position) { create(:character_position, character: character, zone: city_zone, x: 5, y: 5) }
    before { sign_in user, scope: :user }

    def city_action_params(hotspot)
      offer = create(
        :world_action_offer,
        character:,
        zone: position.zone,
        x: position.x,
        y: position.y,
        action_type: hotspot.world_action_type,
        target: hotspot
      )
      {hotspot_id: hotspot.id, action_key: offer.action_key}
    end

    context "with open_feature hotspot (Arena)" do
      let!(:arena_hotspot) do
        create(:city_hotspot, :arena,
          zone: city_zone,
          required_level: 1,
          active: true)
      end

      describe "HTML format" do
        it "redirects to arena page on success" do
          post interact_hotspot_world_path, params: city_action_params(arena_hotspot)

          expect(response).to redirect_to("/arena")
        end

        it "includes success notice in flash" do
          post interact_hotspot_world_path, params: city_action_params(arena_hotspot)

          expect(flash[:notice]).to include("Arena")
        end
      end

      describe "Turbo Stream format" do
        it "returns 303 See Other redirect for proper Turbo handling" do
          post interact_hotspot_world_path,
            params: city_action_params(arena_hotspot),
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to have_http_status(:see_other)
        end

        it "redirects to arena page" do
          post interact_hotspot_world_path,
            params: city_action_params(arena_hotspot),
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to redirect_to("/arena")
        end

        it "sets flash notice before redirect" do
          post interact_hotspot_world_path,
            params: city_action_params(arena_hotspot),
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(flash[:notice]).to include("Entered")
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
        post interact_hotspot_world_path, params: city_action_params(shop_hotspot)

        expect(response).to redirect_to("/shop")
        expect(flash[:notice]).to include("Shop")
      end

      it "returns a turbo redirect to the shop" do
        post interact_hotspot_world_path,
          params: city_action_params(shop_hotspot),
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
          post interact_hotspot_world_path, params: city_action_params(exit_hotspot)

          expect(response).to redirect_to(world_path)
        end

        it "updates character position to destination zone" do
          post interact_hotspot_world_path, params: city_action_params(exit_hotspot)

          position.reload
          expect(position.zone).to eq(destination_zone)
        end

        it "uses the authored gate coordinates" do
          post interact_hotspot_world_path, params: city_action_params(exit_hotspot)

          position.reload
          expect(position.x).to eq(7)
          expect(position.y).to eq(0)
        end
      end

      describe "Turbo Stream format" do
        it "returns 303 See Other redirect for proper Turbo handling" do
          post interact_hotspot_world_path,
            params: city_action_params(exit_hotspot),
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to have_http_status(:see_other)
        end

        it "redirects to world path" do
          post interact_hotspot_world_path,
            params: city_action_params(exit_hotspot),
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
        post interact_hotspot_world_path, params: city_action_params(high_level_hotspot)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("level 50")
      end

      it "returns turbo stream error for Turbo format" do
        post interact_hotspot_world_path,
          params: city_action_params(high_level_hotspot),
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
        post interact_hotspot_world_path, params: city_action_params(inactive_hotspot)

        expect(response).to redirect_to(world_path)
        follow_redirect!
        expect(response.body).to include("unavailable")
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
        expect(response.body).to include("Shop")
        expect(response.body).to include("Outpost Gate")
      end

      it "includes form for each interactive hotspot" do
        get world_path

        expect(response.body).to include("interact_hotspot")
        expect(response.body).to include(arena.id.to_s)
        expect(response.body).to include(shop.id.to_s)
      end

      it "arena hotspot navigates to arena page" do
        post interact_hotspot_world_path,
          params: city_hotspot_action_params(character:, position:, hotspot: arena)

        expect(response).to redirect_to("/arena")
      end

      it "shop hotspot navigates to the shop page" do
        post interact_hotspot_world_path,
          params: city_hotspot_action_params(character:, position:, hotspot: shop)

        expect(response).to redirect_to("/shop")
        expect(flash[:notice]).to include("Shop")
      end

      it "exit gate transitions to destination zone" do
        post interact_hotspot_world_path,
          params: city_hotspot_action_params(character:, position:, hotspot: exit_gate)

        expect(response).to redirect_to(world_path)
        position.reload
        expect(position.zone.location_type).to eq("outdoor")
      end
    end
  end

  describe "GET /world/players" do
    let(:user) { create(:user) }
    let(:zone) do
      create(:zone, name: "Presence Fields", location_type: "outdoor", width: 20, height: 20)
    end
    let(:character) { create(:character, user:, name: "PresenceOwner", level: 10) }
    let!(:position) do
      create(:character_position, character:, zone:, x: 4, y: 7)
    end
    let!(:low_level_player) do
      create(:character, name: "AlphaNearby", level: 2).tap do |nearby|
        create(:character_position, character: nearby, zone:, x: 4, y: 7)
      end
    end
    let!(:high_level_player) do
      create(:character, name: "ZuluNearby", level: 19).tap do |nearby|
        create(:character_position, character: nearby, zone:, x: 4, y: 7)
      end
    end
    let!(:other_cell_player) do
      create(:character, name: "HiddenNeighbor", level: 30).tap do |nearby|
        create(:character_position, character: nearby, zone:, x: 5, y: 7)
      end
    end

    before { sign_in user, scope: :user }

    it "renders only other players at the authoritative current cell" do
      get players_world_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("AlphaNearby", "ZuluNearby")
      expect(response.body).not_to include("PresenceOwner", "HiddenNeighbor")
      expect(response.body).not_to include("<html")
    end

    it "sorts the refresh by the requested level order" do
      get players_world_path, params: {sort: "lvl-desc"}

      expect(response.body.index("ZuluNearby")).to be < response.body.index("AlphaNearby")
    end

    it "falls back to alphabetical order for a missing or unknown sort" do
      get players_world_path, params: {sort: nil}
      nil_sort_body = response.body

      get players_world_path, params: {sort: "not-a-sort"}

      expect(nil_sort_body.index("AlphaNearby")).to be < nil_sort_body.index("ZuluNearby")
      expect(response.body.index("AlphaNearby")).to be < response.body.index("ZuluNearby")
    end

    it "returns the compact empty state at an unoccupied boundary cell" do
      position.update!(x: 0, y: 0)

      get players_world_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No players nearby")
    end

    it "requires authentication" do
      sign_out user

      get players_world_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
