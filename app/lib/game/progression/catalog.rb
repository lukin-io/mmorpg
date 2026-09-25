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

      def level(level_number)
        levels[level_number.to_i]
      end

      def starter
        level(0).slice(*REQUIRED_REWARD_KEYS)
      end

      def rewards_for_level(level_number)
        level(level_number)&.slice(*REQUIRED_REWARD_KEYS)
      end

      # Returns the cumulative combat-experience threshold for reaching the
      # requested level. Soft-release Ashen curve (Curves) owns the number;
      # a target without a complete reward row remains unsupported.
      def experience_threshold_to_reach(level_number)
        target = level_number.to_i
        return 0 if target <= 0
        return unless level(target)

        Game::Progression::Curves.cumulative_threshold(target)
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

        # Soft-release XP thresholds are formula-driven (Curves). YAML
        # experience_to_next_level remains for docs/compat; Curves must stay
        # strictly increasing across the authored level range.
        max_level = entries.keys.max
        thresholds = (1..max_level).map { |lvl| Game::Progression::Curves.cumulative_threshold(lvl) }
        raise "Experience thresholds must be strictly increasing" unless thresholds.each_cons(2).all? { |left, right| right > left }
      end
      private_class_method :validate!
    end
  end
end
