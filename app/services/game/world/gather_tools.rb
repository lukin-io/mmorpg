# frozen_string_literal: true

module Game
  module World
    # Soft-release gather tools. Dig/Look need hatchet/sickle. Fish needs any
    # owned fishing rod (tiered rods live in FishingCatalog).
    class GatherTools
      TOOLS = {
        "digging" => "ashen_hatchet",
        "resource_search" => "ashen_sickle",
        "fishing" => "ashen_fishing_rod"
      }.freeze

      LABELS = {
        "ashen_hatchet" => "Топор Угля",
        "ashen_sickle" => "Серп Пепла",
        "ashen_fishing_rod" => "Удочка Завесы"
      }.freeze

      def self.required_key_for(local_action_type)
        TOOLS[local_action_type.to_s]
      end

      def self.owned?(character, item_key)
        return false unless character&.inventory && item_key.present?

        if item_key.to_s == "ashen_fishing_rod" || FishingCatalog::RODS.key?(item_key.to_s)
          return FishingCatalog.best_rod(character).present?
        end

        character.inventory.inventory_items.joins(:item_template)
          .where(item_templates: {key: item_key})
          .detect { |item| !item.broken? }
          .present?
      end

      def self.wear!(character, item_key)
        item = character.inventory&.inventory_items&.joins(:item_template)
          &.where(item_templates: {key: item_key})&.detect { |candidate| !candidate.broken? }
        return unless item&.durable?

        remaining = item.decrement_durability!
        return remaining if remaining.positive?

        inventory = item.inventory
        inventory.update!(current_weight: [inventory.current_weight.to_i - item.weight.to_i, 0].max)
        item.destroy!
        0
      end

      def self.ensure_templates!
        LABELS.each do |key, name|
          Game::Professions::Templates.send(:ensure_item!,
            key:,
            name:,
            item_type: "tool",
            slot: "none",
            weight: 2,
            stack_limit: 1,
            base_price: 25,
            durability_max: key == "ashen_fishing_rod" ? 60 : 50,
            enhancement_rules: {
              "inventory_family" => "things",
              "subcategory" => "tools",
              "source_name" => name,
              "description" => "Инструмент берега для добычи. Теряет 1 прочность за успешный сбор.",
              "gather_tool" => true
            }
          )
        end
        FishingCatalog.ensure_templates!
      end
    end
  end
end
