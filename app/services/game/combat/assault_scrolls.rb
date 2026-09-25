# frozen_string_literal: true

module Game
  module Combat
    # Assault scroll tiers for Neverlands-style PvP trauma.
    # Trauma severity is owned by the scroll, never by crit intensity.
    module AssaultScrolls
      KINDS = {
        "peaceful" => {
          key: "assault_scroll_peaceful",
          trauma_percent: 0,
          price_vm: 8
        },
        "normal" => {
          key: "assault_scroll_normal",
          trauma_percent: 30,
          price_vm: 15
        },
        "bloody" => {
          key: "assault_scroll_bloody",
          trauma_percent: 100,
          price_vm: 35
        }
      }.freeze

      LEGACY_BLOODY_KEY = "combat_trauma_scroll"
      PROTECTION_KEY = "protection_scroll"
      HEAL_KEY = "combat_heal_scroll"

      module_function

      def normalize_kind(raw)
        kind = raw.to_s.presence || "normal"
        return kind if KINDS.key?(kind)

        "normal"
      end

      def item_key_for(kind)
        KINDS.fetch(normalize_kind(kind)).fetch(:key)
      end

      def trauma_percent_for(kind)
        KINDS.fetch(normalize_kind(kind)).fetch(:trauma_percent)
      end

      def bloody?(kind)
        normalize_kind(kind) == "bloody"
      end

      def consumable_keys
        KINDS.values.map { |row| row[:key] } + [LEGACY_BLOODY_KEY, PROTECTION_KEY, HEAL_KEY]
      end

      def resolve_owned_key(character, kind)
        preferred = item_key_for(kind)
        return preferred if quantity(character, preferred).positive?
        return LEGACY_BLOODY_KEY if bloody?(kind) && quantity(character, LEGACY_BLOODY_KEY).positive?

        preferred
      end

      def quantity(character, item_key)
        return 0 unless character&.inventory

        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: item_key.to_s)
        return 0 unless template

        character.inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
      end

      def total_assault_quantity(character)
        KINDS.keys.sum { |kind| quantity(character, item_key_for(kind)) } +
          quantity(character, LEGACY_BLOODY_KEY)
      end

      def preferred_owned_kind(character)
        %w[bloody normal peaceful].find do |kind|
          quantity(character, item_key_for(kind)).positive? ||
            (bloody?(kind) && quantity(character, LEGACY_BLOODY_KEY).positive?)
        end
      end
    end
  end
end
