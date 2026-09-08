# frozen_string_literal: true

require "digest"

module Game
  module World
    # Loads bounded authored routes and resolves their explicit city/region
    # endpoints. Missing destination, dated schedule, duration, or path leaves a
    # displayed fare unavailable. It never creates regions or invents schedules.
    class AirshipRoutes
      class InvalidConfigurationError < StandardError; end

      CONFIG_PATH = Rails.root.join("config/gameplay/airship_routes.yml")
      MAX_ROUTES = 64
      Route = Data.define(:key, :label, :fare_nv, :departs_at, :attributes, :revision) do
        def available?
          attributes.present?
        end
      end

      def initialize(config: nil)
        definitions = config.nil? ? YAML.safe_load_file(CONFIG_PATH) : config
        raise InvalidConfigurationError, "Airship routes must be a bounded mapping" unless definitions.is_a?(Hash)

        @config = definitions.deep_stringify_keys
        validate_definitions!
      end

      # Returns current-station rows with either a complete immutable reservation
      # snapshot or no bookable attributes. Reads only declared route endpoints.
      def for_station(character:, position:, at: Time.current)
        return [] unless station_available?(position&.zone, character)

        config.filter_map do |key, definition|
          next unless definition.fetch("source_zone") == position.zone.name

          resolve(key, definition, character, position, at)
        end
      end

      def station_available?(zone, character)
        zone&.city? && CityHotspot.active.where(zone:, action_type: "open_feature")
          .where("action_params ->> 'feature' = ?", "airship_station")
          .where("required_level <= ?", character.level).exists?
      end

      private

      attr_reader :config

      def validate_definitions!
        raise InvalidConfigurationError, "Airship routes must be a bounded mapping" unless config.size <= MAX_ROUTES

        config.each do |key, definition|
          unless key.match?(/\A[a-z][a-z0-9_]{0,63}\z/) && definition.is_a?(Hash) &&
              %w[source_zone label route_label].all? { |field| definition[field].is_a?(String) && definition[field].present? }
            raise InvalidConfigurationError, "Airship routes require stable identities and labels"
          end
          fare = BigDecimal(definition["fare_nv"].to_s, exception: false)
          unless fare&.finite? && fare.positive? && fare == fare.round(2) && fare < 10_000_000_000
            raise InvalidConfigurationError, "Airship fare must be positive NV with at most two decimal places"
          end
          if definition.key?("departures") && (!definition["departures"].is_a?(Array) || definition["departures"].size > 128)
            raise InvalidConfigurationError, "Airship departures must be a bounded dated list"
          end
          if definition.key?("waypoints") && (!definition["waypoints"].is_a?(Array) || definition["waypoints"].size > AirshipJourney::MAX_WAYPOINTS)
            raise InvalidConfigurationError, "Airship waypoints must be a bounded list"
          end
        end
      end

      def resolve(key, definition, character, position, at)
        departure = Array(definition["departures"]).filter_map { |value| parse_departure(value) }.select { |time| time > at }.min
        attributes = reservation_attributes(key, definition, character, position, departure, at)
        Route.new(
          key:, label: definition.fetch("label"), fare_nv: BigDecimal(definition.fetch("fare_nv").to_s),
          departs_at: departure, attributes:,
          revision: Digest::SHA256.hexdigest([definition, position.zone_id, position.x, position.y, departure&.iso8601(6)].to_json)
        )
      end

      def reservation_attributes(key, definition, character, position, departure, at)
        duration = definition["duration_seconds"]
        return unless departure && duration.is_a?(Integer) && duration.positive?

        destination = Zone.find_by(name: definition["destination_zone"])
        return unless station_available?(destination, character)

        points = resolve_waypoints(definition["waypoints"])
        return unless points

        attributes = {
          route_key: key, route_label: definition.fetch("route_label"),
          source_zone: position.zone, source_x: position.x, source_y: position.y,
          destination_zone: destination, destination_x: definition["destination_x"], destination_y: definition["destination_y"],
          fare_nv: definition.fetch("fare_nv"), boarded_at: at,
          departs_at: departure, arrives_at: departure + duration, waypoints: points,
          last_position_zone: position.zone, last_position_x: position.x, last_position_y: position.y
        }
        # Reuse the durable snapshot validation; unassigned owner/offer are the
        # only expected missing associations during this availability check.
        candidate = AirshipJourney.new(attributes.merge(character:))
        candidate.valid?
        return if candidate.errors.attribute_names.any? { |attribute| !%i[boarding_offer boarding_offer_id].include?(attribute) }

        attributes.except(:boarded_at)
      end

      def resolve_waypoints(definitions)
        return unless definitions.is_a?(Array) && definitions.size.between?(2, AirshipJourney::MAX_WAYPOINTS)
        return unless definitions.all? { |point| point.is_a?(Hash) && point["zone"].is_a?(String) }

        zones = Zone.where(name: definitions.pluck("zone").uniq).index_by(&:name)
        definitions.map do |point|
          {"offset_seconds" => point["offset_seconds"], "zone_id" => zones[point["zone"]]&.id, "x" => point["x"], "y" => point["y"]}
        end
      end

      def parse_departure(value)
        Time.iso8601(value) if value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
      rescue ArgumentError
        nil
      end
    end
  end
end
