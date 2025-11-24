# frozen_string_literal: true

module Game
  module Movement
    # TerrainModifier reads tile metadata to scale turn cooldowns for movement.
    #
    # Usage:
    #   modifier = Game::Movement::TerrainModifier.new(zone: zone)
    #   modifier.cooldown_seconds(base_seconds: 2, tile_metadata: {"movement_modifier" => "swamp"})
    #
    # Returns:
    #   Float cooldown seconds adjusted by terrain multiplier.
    class TerrainModifier
      CONFIG_PATH = Rails.root.join("config/gameplay/terrain_modifiers.yml")

      def self.config
        @config ||= YAML.safe_load(CONFIG_PATH.read).with_indifferent_access
      end

      def initialize(zone:)
        @zone = zone
      end

      def cooldown_seconds(base_seconds:, tile_metadata:)
        (base_seconds * speed_multiplier(tile_metadata:)).round(2)
      end

      def speed_multiplier(tile_metadata:)
        key = terrain_key(tile_metadata)
        rule = config[key] || config["default"]
        rule.fetch("speed_multiplier", 1.0).to_f
      end

      private

      attr_reader :zone

      def terrain_key(tile_metadata)
        [
          tile_metadata["movement_modifier"],
          tile_metadata["terrain_type"],
          tile_metadata["terrain"],
          zone&.metadata&.dig("default_movement_modifier")
        ].compact.map { |value| value.to_s.parameterize.underscore }.find(&:present?) || "default"
      end

      def config
        self.class.config
      end
    end
  end
end
