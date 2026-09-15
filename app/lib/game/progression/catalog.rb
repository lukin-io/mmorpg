# frozen_string_literal: true

require "yaml"

module Game
  module Progression
    # Loads and validates the source-backed Neverlands level/grant table.
    module Catalog
      CONFIG_PATH = Rails.root.join("config/gameplay/character_progression.yml")
      REQUIRED_REWARD_KEYS = %w[
        stat_points
        nv
        perk_points
        peace_skill_points
        combat_skill_points
        fight_experience_cap
        max_npcs_in_group
      ].freeze

      module_function

      def levels
        @levels ||= begin
          raw = YAML.safe_load_file(CONFIG_PATH, aliases: false).fetch("levels")
          normalized = raw.to_h.transform_keys { |level| Integer(level) }
            .transform_values(&:deep_stringify_keys)
          validate!(normalized)
          normalized.freeze
        end
      end

      def reload!
        @levels = nil
        levels
      end

      # Returns the source row for a current level. Its experience_to_next_level
      # value is the cost of that level only, not a cumulative XP threshold.
      def level(level_number)
        levels[level_number.to_i]
      end

      def starter
        level(0).slice(*REQUIRED_REWARD_KEYS)
      end

      def rewards_for_level(level_number)
        level(level_number)&.slice(*REQUIRED_REWARD_KEYS)
      end

      # Returns total combat XP needed to reach a level by summing the costs of
      # all preceding rows. September 11 live proof: level 17 XP 29,946,496 plus
      # 20,053,504 remaining equals the level 18 threshold of 50,000,000.
      # A target without a complete grant row remains unsupported, even when
      # the previous row publishes its cost (in particular, target level 28).
      # @param level_number [Integer] target level, not the current level
      # @return [Integer, nil] cumulative threshold, or nil beyond complete rows
      def experience_threshold_to_reach(level_number)
        target = level_number.to_i
        return 0 if target <= 0
        return unless level(target)

        (0...target).sum { |current_level| levels.fetch(current_level).fetch("experience_to_next_level") }
      end

      def fight_experience_cap(level_number)
        level(level_number)&.fetch("fight_experience_cap", 0).to_i
      end

      def maximum_supported_level
        levels.keys.max
      end

      def validate!(entries)
        raise "Progression table must start at level 0" unless entries.key?(0)
        expected_levels = (0..entries.keys.max).to_a
        raise "Progression levels must be contiguous" unless entries.keys.sort == expected_levels

        entries.each do |level_number, row|
          missing = ["experience_to_next_level", *REQUIRED_REWARD_KEYS] - row.keys
          raise "Progression level #{level_number} is missing #{missing.join(', ')}" if missing.any?

          row.each do |key, value|
            raise "Progression level #{level_number} #{key} must be a non-negative integer" unless value.is_a?(Integer) && value >= 0
          end
        end

        costs = entries.values.map { |row| row.fetch("experience_to_next_level") }
        raise "Per-level experience costs must be positive" unless costs.all?(&:positive?)
      end
      private_class_method :validate!
    end
  end
end
