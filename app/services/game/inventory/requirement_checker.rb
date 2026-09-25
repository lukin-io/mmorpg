# frozen_string_literal: true

module Game
  module Inventory
    # Validates item requirements against a character before equip/use actions.
    class RequirementChecker
      STAT_ALIASES = {
        "strength" => :strength,
        "dexterity" => :dexterity,
        "luck" => :luck,
        "intelligence" => :intelligence,
        "knowledge" => :intelligence,
        "vitality" => :vitality,
        "health" => :vitality
      }.freeze

      IGNORED_KEYS = %w[mass weight price durability current_durability max_durability].freeze
      SKILL_ALIASES = {
        "unarmed_skill" => :unarmed_combat,
        "unarmed_combat" => :unarmed_combat,
        "knife_skill" => :knife_mastery,
        "knife_mastery" => :knife_mastery,
        "sword_skill" => :sword_mastery,
        "sword_mastery" => :sword_mastery,
        "axe_skill" => :axe_mastery,
        "axe_mastery" => :axe_mastery,
        "blunt_skill" => :bludgeoning_mastery,
        "bludgeoning_skill" => :bludgeoning_mastery,
        "bludgeoning_mastery" => :bludgeoning_mastery,
        "throwing_skill" => :throwing_mastery,
        "throwing_mastery" => :throwing_mastery,
        "polearm_skill" => :polearm_mastery,
        "polearm_mastery" => :polearm_mastery,
        "staff_skill" => :staff_mastery,
        "staff_mastery" => :staff_mastery,
        "two_handed_skill" => :two_handed_mastery,
        "two_handed_mastery" => :two_handed_mastery,
        "dual_wield_skill" => :dual_wielding,
        "dual_wielding" => :dual_wielding,
        "linguistics" => :linguistics,
        "stealth" => :stealth
      }.freeze

      def self.call(character:, item:)
        new(character:, item:).call
      end

      def initialize(character:, item:)
        @character = character
        @item = item
      end

      def call
        return failure(I18n.t("game.inventory.wear_item_broken")) if item.broken?
        return failure(I18n.t("game.inventory.wear_item_expired")) if item.expired?

        missing = missing_requirements
        return {allowed: true, missing: []} if missing.empty?

        {
          allowed: false,
          missing: missing,
          error: I18n.t("game.inventory.requirements_not_met", list: missing.map { |entry| entry[:label] }.join(", "))
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

          {
            key:,
            required: required.to_i,
            current:,
            label: I18n.t(
              "game.inventory.requirement_label",
              name: requirement_name(key),
              required: required.to_i,
              current:
            )
          }
        end
      end

      def requirement_name(key)
        normalized = normalize_key(key)
        return I18n.t("game.details.level") if normalized == "level"

        detail_key = InventoriesHelper::ITEM_DETAIL_I18N_KEYS[normalized]
        return I18n.t("game.details.#{detail_key}") if detail_key

        skill_key = InventoriesHelper::ITEM_SKILL_I18N_KEYS[normalized]
        return I18n.t("game.skills.#{skill_key}") if skill_key

        I18n.t("game.details.#{normalized}", default: normalized.tr("_", " "))
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

        flat
      end

      def current_value_for(key)
        normalized = normalize_key(key)
        return character.level.to_i if normalized == "level"
        return character.max_action_points.to_i if %w[ap action_points].include?(normalized)

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
