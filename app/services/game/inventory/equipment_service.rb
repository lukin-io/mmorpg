# frozen_string_literal: true

module Game
  module Inventory
    # Handles equipping and unequipping items.
    class EquipmentService
      attr_reader :character, :item, :slot

      def initialize(character:, item: nil, slot: nil)
        @character = character
        @item = item
        @slot = slot
      end

      def equip!
        return {success: false, error: "Item not found"} unless item
        return {success: false, error: "Item is not equipment"} unless item.item_template.equippable?

        target_slot = item.item_template.equipment_slot.to_sym
        return {success: false, error: "Invalid equipment slot"} unless valid_slot?(target_slot)

        # Unequip existing item in slot
        existing = equipped_in_slot(target_slot)
        existing&.update!(equipped: false, equipment_slot: nil)

        # Equip new item
        item.update!(equipped: true, equipment_slot: target_slot)

        {success: true, equipped_item: item, unequipped_item: existing}
      end

      def unequip!
        return {success: false, error: "Slot not specified"} unless slot

        existing = equipped_in_slot(slot)
        return {success: false, error: "No item in slot"} unless existing

        existing.update!(equipped: false, equipment_slot: nil)
        {success: true, unequipped_item: existing}
      end

      private

      def valid_slot?(slot)
        %i[head chest legs feet hands main_hand off_hand ring_1 ring_2 amulet].include?(slot)
      end

      def equipped_in_slot(slot)
        character.inventory.inventory_items.find_by(equipped: true, equipment_slot: slot)
      end
    end
  end
end
