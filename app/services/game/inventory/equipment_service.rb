# frozen_string_literal: true

module Game
  module Inventory
    # EquipmentService enforces slot restrictions + class-specific equipment rules.
    #
    # Usage:
    #   Game::Inventory::EquipmentService.new(character:).equip!(item:)
    #
    # Returns:
    #   Updated InventoryItem.
    class EquipmentService
      ALLOWED_SLOTS = %w[weapon offhand head chest legs hands feet accessory consumable].freeze

      def initialize(character:)
        @character = character
      end

      def equip!(item:)
        validate_slot!(item)

        InventoryItem.transaction do
          unequip_conflicts(item.slot_kind)
          item.update!(equipped: true, slot_kind: item.item_template.slot)
        end

        item
      end

      def unequip!(item:)
        item.update!(equipped: false)
      end

      private

      attr_reader :character

      def validate_slot!(item)
        slot = item.item_template.slot
        raise ArgumentError, "Unknown equipment slot #{slot}" unless ALLOWED_SLOTS.include?(slot)
        return if character.character_class.blank?

        allowed_tags = character.character_class.equipment_tags
        return if allowed_tags.blank? || allowed_tags.include?(slot)

        raise Pundit::NotAuthorizedError, "Class cannot equip #{slot}"
      end

      def unequip_conflicts(slot)
        character.inventory.inventory_items.where(slot_kind: slot, equipped: true).update_all(equipped: false)
      end
    end
  end
end

