# frozen_string_literal: true

module Game
  module Inventory
    # Handles equipment enhancement/upgrade.
    class EnhancementService
      attr_reader :character, :item

      def initialize(character:, item:)
        @character = character
        @item = item
      end

      def enhance!
        return {success: false, error: "Item cannot be enhanced"} unless item.item_template.enhanceable?
        return {success: false, error: "Max enhancement level reached"} if at_max_level?

        next_level = current_level + 1
        cost = calculate_cost(next_level)
        materials = calculate_materials(next_level)

        return {success: false, error: "Not enough gold"} if character.gold < cost
        return {success: false, error: "Missing materials"} unless has_materials?(materials)

        # Consume resources
        character.decrement!(:gold, cost)
        consume_materials!(materials)

        # Roll for success
        success_rate = calculate_success_rate(next_level)
        success = rand(100) < success_rate

        if success
          item.update!(enhanced_level: next_level)
          {success: true, level_up: true, new_level: next_level}
        else
          {success: true, level_up: false, new_level: current_level}
        end
      end

      private

      def current_level
        item.enhanced_level.to_i
      end

      def at_max_level?
        current_level >= max_level
      end

      def max_level
        case item.item_template.rarity
        when "common" then 5
        when "uncommon" then 7
        when "rare" then 10
        when "epic" then 12
        when "legendary" then 15
        else 5
        end
      end

      def calculate_cost(level)
        base_cost = 100
        multiplier = 1.5**level
        (base_cost * multiplier * rarity_multiplier).to_i
      end

      def rarity_multiplier
        case item.item_template.rarity
        when "common" then 1.0
        when "uncommon" then 1.2
        when "rare" then 1.5
        when "epic" then 2.0
        when "legendary" then 3.0
        else 1.0
        end
      end

      def calculate_materials(level)
        material_key = case item.item_template.item_type
        when "weapon" then "weapon_stone"
        when "armor" then "armor_stone"
        else "enhancement_stone"
        end

        {material_key: material_key, quantity: [level, 1].max}
      end

      def has_materials?(materials)
        mat = character.inventory.inventory_items
          .joins(:item_template)
          .find_by(item_templates: {item_key: materials[:material_key]})

        mat && mat.quantity >= materials[:quantity]
      end

      def consume_materials!(materials)
        mat = character.inventory.inventory_items
          .joins(:item_template)
          .find_by(item_templates: {item_key: materials[:material_key]})

        return unless mat

        new_qty = mat.quantity - materials[:quantity]
        if new_qty <= 0
          mat.destroy
        else
          mat.update!(quantity: new_qty)
        end
      end

      def calculate_success_rate(level)
        base_rate = 100
        rate = base_rate - (level * 8)
        rate += (character.luck || 0) / 10
        rate.clamp(5, 100)
      end
    end
  end
end
