# frozen_string_literal: true

module Game
  module World
    # Returns up to ten online playable characters, the full audience count,
    # and an authored label for the exact cell, validated room, or aboard flight.
    # The viewer participates in the same sorted audience as other characters.
    # Inputs are authoritative character/position records plus an allowlisted
    # sort key. Reads authored room access, audience count, and a bounded list;
    # never changes position, resume context, sessions, or chat audiences.
    class Presence
      Result = Struct.new(:players, :label, :count, keyword_init: true)
      SORT_ORDERS = {
        "az" => {name: :asc},
        "za" => {name: :desc},
        "lvl-asc" => {level: :asc, name: :asc},
        "lvl-desc" => {level: :desc, name: :asc}
      }.freeze
      LIMIT = 10

      def initialize(character:, position: nil, sort: "az")
        @character = character
        @position = position || character&.position
        @sort = sort
      end

      def call
        return Result.new(players: [], label: "Unknown", count: 0) unless position

        scope = online_characters
        if aboard_journey
          passengers = AirshipJourney.aboard.where(route_key: aboard_journey.route_key,
            departs_at: aboard_journey.departs_at)
          scope = scope.where(id: passengers.select(:character_id))
        else
          scope = scope.where(character_positions: {zone_id: position.zone_id, x: position.x, y: position.y})
            .where.not(id: AirshipJourney.aboard.select(:character_id))
          scope = scope_to_location(scope) if location
          scope = scope_to_city_rooms(scope) if position.zone.city?
        end
        players = scope.order(SORT_ORDERS.fetch(sort.to_s, SORT_ORDERS.fetch("az"))).limit(LIMIT).to_a
        Result.new(players:, label:, count: scope.count)
      end

      # Shared location text for map descriptions and profiles. Resolves only
      # the character's cell/room/flight; it never loads or counts an audience.
      def label
        return "Unknown" unless position
        return aboard_journey.route_label if aboard_journey
        return current_city_room.fetch(:label) if current_city_room
        return entrance&.presence_label || cell_presence_label || position.zone.display_name unless location

        case room
        when :interior
          location.location_presence_label
        when :shop
          feature = location.location_features.find { |entry| entry["feature"] == "shop" }
          feature["presence_label"].presence || feature.fetch("label")
        else
          location.presence_label
        end
      end

      # Chat uses the same captured cell/room partition, with stable record ids
      # instead of authored display labels. No player list is loaded here.
      def context_key
        return unless position
        return "airship:#{aboard_journey.flight_key}" if aboard_journey

        parts = ["zone", position.zone_id, "cell", position.x, position.y]
        # Existing village chat keys remain stable as additional lobby kinds
        # reuse the same validated interior context.
        parts.concat(["location", location.location_key, (room == :interior ? location.location_kind : room)]) if location
        parts.concat(["room", current_city_room.fetch(:key)]) if current_city_room
        parts.join(":")
      end

      private

      attr_reader :character, :position, :sort

      def online_characters
        Character.joins(:position)
          .where(character_positions: {state: CharacterPosition.states.fetch("active")})
          .where(user_id: UserSession.recent.select(:user_id))
          .where(<<~SQL.squish)
            characters.id = (
              SELECT playable.id FROM characters playable
              WHERE playable.user_id = characters.user_id
              ORDER BY playable.created_at, playable.id LIMIT 1
            )
          SQL
      end

      def aboard_journey
        return @aboard_journey if defined?(@aboard_journey)

        @aboard_journey = AirshipJourney.aboard.find_by(character_id: character&.id)
      end

      def current_city_room
        return @current_city_room if defined?(@current_city_room)

        @current_city_room = position.zone.city? ? resolve_city_room : nil
      end

      def resolve_city_room
        context = character.gameplay_context
        resume = Game::World::ResumeContext.new(character:)
        case context["name"]
        when "shop"
          {key: "shop", label: "Shop", context: {name: "shop", params: {}}} if resume.shop_available?
        when "city_building"
          key = context.dig("params", "building_key")
          if Game::World::CityBuildingCatalog.accessible?(character:, building_key: key)
            {key: "building:#{key}", label: Game::World::CityBuildingCatalog.fetch(key, zone: position.zone).fetch("title"),
             context: {name: "city_building", params: {building_key: key}}}
          end
        when "arena_room"
          room = resume.arena_room
          if room
            {key: "arena:#{room.id}", label: room.name, context: {name: "arena_room", params: {room_id: room.id}}}
          end
        end
      end

      def city_feature_levels
        @city_feature_levels ||= CityHotspot.active.where(zone_id: position.zone_id, action_type: "open_feature")
          .where("action_params ->> 'feature' IN (?)", ["shop", "arena", *Game::World::CityBuildingCatalog::BUILDINGS.keys])
          .group("action_params ->> 'feature'").minimum(:required_level)
      end

      def scope_to_city_rooms(scope)
        rooms = scope.none
        city_feature_levels.each do |feature, level|
          candidates = scope.where("characters.level >= ?", level)
          candidates = if feature == "arena"
            arena_room_scope(candidates)
          else
            context = feature == "shop" ? {name: "shop", params: {}} :
              {name: "city_building", params: {building_key: feature}}
            candidates.where("characters.metadata @> ?::jsonb", {gameplay_context: context}.to_json)
          end
          rooms = rooms.or(candidates)
        end

        if current_city_room
          rooms.where("characters.metadata @> ?::jsonb", {gameplay_context: current_city_room.fetch(:context)}.to_json)
        else
          scope.where.not(id: rooms.select(:id))
        end
      end

      def arena_room_scope(scope)
        scope.where("characters.metadata @> ?::jsonb", {gameplay_context: {name: "arena_room", params: {}}}.to_json)
          .where("jsonb_typeof(characters.metadata #> '{gameplay_context,params,room_id}') = 'number'")
          .where(<<~SQL.squish, position.zone_id)
            EXISTS (
              SELECT 1 FROM arena_rooms
              WHERE arena_rooms.id::text = characters.metadata #>> '{gameplay_context,params,room_id}'
                AND arena_rooms.active = TRUE
                AND (arena_rooms.zone_id IS NULL OR arena_rooms.zone_id = ?)
                AND characters.level BETWEEN arena_rooms.level_min AND arena_rooms.level_max
                AND (arena_rooms.alignment_restriction IS NULL OR arena_rooms.alignment_restriction = ''
                     OR arena_rooms.alignment_restriction = characters.alignment)
            )
          SQL
      end

      def entrance
        return @entrance if defined?(@entrance)

        building = TileBuilding.active.at_tile(position.zone.name, position.x, position.y) if position.zone.outdoor?
        @entrance = (building if building&.can_enter?(character))
      end

      def location
        entrance if entrance&.location?
      end

      def room
        context = character.gameplay_context
        return :interior if context["name"] == "world_location" && context.dig("params", "key") == location.location_key
        return :shop if context["name"] == "shop" && location.location_feature_available?("shop")

        :outdoors
      end

      def scope_to_location(scope)
        interior_context = {gameplay_context: {name: "world_location", params: {key: location.location_key}}}.to_json
        shop_context = {gameplay_context: {name: "shop", params: {}}}.to_json
        case room
        when :interior
          scope.where("characters.metadata @> ?::jsonb", interior_context)
        when :shop
          scope.where("characters.metadata @> ?::jsonb", shop_context)
        else
          scope = scope.where.not("characters.metadata @> ?::jsonb", interior_context)
          if location.location_feature_available?("shop")
            scope = scope.where.not("characters.metadata @> ?::jsonb", shop_context)
          end
          scope
        end
      end

      # Only the viewer's exact outdoor cell is read. A display label never
      # changes the stable coordinate/room key used for chat and player culling.
      def cell_presence_label
        return unless position.zone.outdoor?
        return @cell_presence_label if defined?(@cell_presence_label)

        @cell_presence_label = MapTileTemplate.find_by(
          zone: position.zone.name, x: position.x, y: position.y
        )&.presence_label
      end
    end
  end
end
