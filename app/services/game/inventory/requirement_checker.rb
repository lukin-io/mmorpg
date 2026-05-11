# frozen_string_literal: true

module Game
  module Inventory
    # Validates item requirements against a character before equip/use actions.
    class RequirementChecker
      STAT_ALIASES = {
        "strength" => :strength,
        "str" => :strength,
        "dexterity" => :dexterity,
        "dex" => :dexterity,
        "agility" => :agility,
        "luck" => :luck,
        "knowledge" => :intelligence,
        "intelligence" => :intelligence,
        "wisdom" => :spirit,
        "spirit" => :spirit,
        "health" => :vitality,
        "vitality" => :vitality,
        "constitution" => :constitution
      }.freeze

      SKILL_ALIASES = {
        "bludgeoning_mastery" => :melee_combat,
        "mace_mastery" => :melee_combat,
        "knife_mastery" => :melee_combat,
        "sword_mastery" => :melee_combat,
        "bow_mastery" => :ranged_combat,
        "observation" => :perception,
        "linguistics" => :trading
      }.freeze

      IGNORED_KEYS = %w[mass weight price durability].freeze

      def self.call(character:, item:)
        new(character:, item:).call
      end

      def initialize(character:, item:)
        @character = character
        @item = item
      end

      def call
        return failure("Item is broken") if item.broken?
        return failure("Item has expired") if item.expired?

        missing = missing_requirements
        return {allowed: true, missing: []} if missing.empty?

        {
          allowed: false,
          missing: missing,
          error: "Requirements not met: #{missing.map { |entry| entry[:label] }.join(", ")}"
        }
      end

      private

      attr_reader :character, :item

      def failure(error)
        {allowed: false, missing: [], error:}
      end

      def missing_requirements
        flattened_requirements.filter_map do |key, required|
          next if required.blank?

          current = current_value_for(key)
          next if current.nil? || current >= required.to_i

          {key:, required: required.to_i, current:, label: "#{key.to_s.titleize} #{required} (current #{current})"}
        end
      end

      def flattened_requirements
        raw = item.requirements
        flat = {}

        raw.each do |key, value|
          normalized_key = normalize_key(key)
          if value.is_a?(Hash)
            value.each { |nested_key, nested_value| flat[normalize_key(nested_key)] = nested_value }
          elsif IGNORED_KEYS.exclude?(normalized_key)
            flat[normalized_key] = value
          end
        end

        legacy_level = item.properties.to_h["level_required"]
        flat["level"] ||= legacy_level if legacy_level.present?
        flat
      end

      def current_value_for(key)
        normalized = normalize_key(key)
        return character.level.to_i if %w[level min_level level_required].include?(normalized)
        return character.max_action_points.to_i if %w[ap action_points action_point_cost].include?(normalized)

        stat_key = STAT_ALIASES[normalized]
        return character.stats.get(stat_key).to_i if stat_key

        skill_key = SKILL_ALIASES.fetch(normalized, normalized.to_sym)
        return character.passive_skill_level(skill_key).to_i if Game::Skills::PassiveSkillRegistry.valid?(skill_key)

        nil
      end

      def normalize_key(key)
        key.to_s.strip.downcase.tr(" -", "_")
      end
    end
  end
end
