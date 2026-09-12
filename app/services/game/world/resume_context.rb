# frozen_string_literal: true

module Game
  module World
    # Persists and resolves the character's last authoritative gameplay
    # surface. Paths are generated from an allowlisted context and sanitized
    # state; browser-provided or persisted arbitrary URLs are never followed.
    class ResumeContext
      include Rails.application.routes.url_helpers

      SHOP_PARAM_KEYS = %w[
        mode
        category
        min_level
        max_level
        min_price
        max_price
      ].freeze
      NUMERIC_SHOP_PARAM_KEYS = %w[min_level max_level min_price max_price].freeze
      ARENA_ENTRY_ZONE_KEY = "arena_entry_zone_id"

      def initialize(character:)
        @character = character
      end

      def remember_world!
        character.remember_gameplay_context!(name: "world")
      end

      def remember_airship!(journey:)
        unless journey.character_id == character.id && journey.aboard?
          raise ArgumentError, "Active owned airship journey required"
        end

        character.remember_gameplay_context!(name: "airship", params: {"journey_id" => journey.id})
      end

      def remember_shop!(params: {})
        character.remember_gameplay_context!(
          name: "shop",
          params: normalized_shop_params(params)
        )
      end

      def remember_city_building!(building_key:)
        normalized_key = building_key.to_s
        raise ArgumentError, "Unsupported city building" unless CityBuildingCatalog.key?(normalized_key)

        character.remember_gameplay_context!(
          name: "city_building",
          params: {"building_key" => normalized_key}
        )
      end

      def remember_world_location!(key:)
        normalized_key = key.to_s
        raise ArgumentError, "World location is unavailable" unless world_location_available?(normalized_key)

        character.remember_gameplay_context!(
          name: "world_location",
          params: {"key" => normalized_key}
        )
      end

      # City building acceptance records entry in its existing transaction.
      # A late cookie response cannot revoke it or select a different room.
      # The initial lobby still shares the current World/chat context.
      def remember_arena_entry!
        character.with_lock do
          next unless arena_available?

          zone_id = character.position.zone_id
          unless character.metadata.to_h[ARENA_ENTRY_ZONE_KEY] == zone_id
            character.update!(metadata: character.metadata.to_h.merge(ARENA_ENTRY_ZONE_KEY => zone_id))
          end
          zone_id
        end
      end

      # A saved entry grants nothing after the current city/building becomes
      # unavailable. Reconstruct access from fresh position and authored data.
      def arena_entered?
        zone_id = character.metadata.to_h[ARENA_ENTRY_ZONE_KEY]
        zone_id.is_a?(Integer) && arena_available? && zone_id == character.position.zone_id
      end

      # Actual room entry owns persistence and the local-chat audience change.
      # A preview cannot select a room, and a stale entry cannot replace a fight.
      # Returns the fresh accessible room, or nil without changing context.
      def remember_arena_room!(room:)
        character.with_lock do
          current_room = ArenaRoom.find_by(id: room&.id)
          next unless arena_room_available?(room: current_room)
          next if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?

          character.remember_gameplay_context!(
            name: "arena_room",
            params: {"room_id" => current_room.id}
          )
          current_room
        end
      end

      # Reconstruct a selected room only from a saved id and current authored
      # city/room access. This also works after a new login without an old cookie.
      def arena_room
        context = character.gameplay_context
        return unless context["name"] == "arena_room"

        room_id = context.dig("params", "room_id")
        return unless room_id.is_a?(Integer) && room_id.positive?

        room = ArenaRoom.find_by(id: room_id)
        room if arena_room_available?(room:)
      end

      def arena_available?
        return false if character.active_airship_journey

        position = character.position&.reload
        return false unless position&.active? && position.zone.city?

        CityHotspot.for_zone(position.zone).any? do |hotspot|
          hotspot.action_type == "open_feature" &&
            hotspot.action_params.to_h["feature"] == "arena" &&
            hotspot.can_interact?(character)
        end
      end

      def arena_room_available?(room:)
        room&.accessible_by?(character) && arena_available?
      end

      def resume_path
        return airship_path if character.active_airship_journey
        result = character.unfinished_arena_result
        return arena_match_path(result) if result

        context = character.gameplay_context

        case context["name"]
        when "shop"
          return world_path unless shop_available?

          shop_path(**normalized_shop_params(context["params"]).symbolize_keys)
        when "city_building"
          building_key = context.dig("params", "building_key").to_s
          return world_path unless CityBuildingCatalog.accessible?(character:, building_key:)

          CityBuildingCatalog.path_for(building_key)
        when "world_location"
          key = context.dig("params", "key").to_s
          return world_path unless world_location_available?(key)

          world_location_path(key)
        when "arena_room"
          room = arena_room
          room ? arena_room_path(room) : world_path
        else
          world_path
        end
      end

      def shop_available?
        return false if character.active_airship_journey

        position = character.position&.reload
        return false unless position

        return true if linked_shop_location(position)
        return false unless position.zone.city?

        CityHotspot.for_zone(position.zone).any? do |hotspot|
          hotspot.action_params.to_h["feature"] == "shop" && hotspot.can_interact?(character)
        end
      end

      # The captured village Shop returns to its accessible parent interior.
      # Resolve it from the persisted entrance cell, never a submitted URL.
      def shop_parent_location
        linked_shop_location(character.position&.reload)
      end

      private

      attr_reader :character

      def world_location_available?(key)
        return false if character.active_airship_journey

        position = character.position&.reload
        building = TileBuilding.active.at_tile(position&.zone&.name, position&.x, position&.y)
        building&.location? && building.location_key == key && building.can_enter?(character)
      end

      def linked_shop_location(position)
        return unless position&.zone&.outdoor?

        building = TileBuilding.active.at_tile(position&.zone&.name, position&.x, position&.y)

        building if building&.location? &&
          building.can_enter?(character) &&
          building.location_feature_available?("shop")
      end

      def normalized_shop_params(params)
        raw = params.respond_to?(:to_h) ? params.to_h.deep_stringify_keys : {}
        normalized = {
          "mode" => normalized_option(raw["mode"], Game::Shop::Catalog::VALID_MODES, "buy"),
          "category" => normalized_option(raw["category"], Game::Shop::Catalog::VALID_CATEGORIES, "knives")
        }

        NUMERIC_SHOP_PARAM_KEYS.each do |key|
          value = Integer(raw[key], exception: false)
          normalized[key] = value.to_s if value&.>= 0
        end

        normalized.slice(*SHOP_PARAM_KEYS)
      end

      def normalized_option(value, allowed, fallback)
        normalized = value.to_s
        allowed.include?(normalized) ? normalized : fallback
      end
    end
  end
end
