# frozen_string_literal: true

module Game
  module Inventory
    # Handles equipping and unequipping items.
    class EquipmentService
      HAND_SLOTS = %i[main_hand off_hand].freeze

      attr_reader :character, :item, :slot

      def initialize(character:, item: nil, slot: nil)
        @character = character
        @item = item
        @slot = slot
      end

      def equip!
        return {success: false, error: "Item not found"} unless item
        return {success: false, error: "Item is not equipment"} unless item.item_template.equippable?
        return {success: false, error: "Item is already equipped"} if item.equipped?

        target_slot = target_slot_for(item)
        return {success: false, error: "Invalid equipment slot"} unless target_slot

        requirements = Game::Inventory::RequirementChecker.call(character:, item:)
        return {success: false, error: requirements[:error]} unless requirements[:allowed]

        unequipped_items = []
        ActiveRecord::Base.transaction do
          unequipped_items = items_to_unequip_for(target_slot, item)
          InventoryItem.where(id: unequipped_items.map(&:id)).update_all(equipped: false, equipment_slot: nil, updated_at: Time.current) if unequipped_items.any?
          item.update!(equipped: true, equipment_slot: target_slot)
        end

        {success: true, equipped_item: item, unequipped_item: unequipped_items.first, unequipped_items:}
      end

      def unequip!
        return {success: false, error: "Slot not specified"} unless slot

        existing = equipped_in_slot(slot)
        return {success: false, error: "No item in slot"} unless existing

        existing.update!(equipped: false, equipment_slot: nil)
        {success: true, unequipped_item: existing}
      end

      def unequip_all!
        equipped_items = character.inventory.inventory_items.equipped.to_a
        return {success: true, count: 0} if equipped_items.empty?

        InventoryItem.where(id: equipped_items.map(&:id)).update_all(
          equipped: false,
          equipment_slot: nil,
          updated_at: Time.current
        )

        {success: true, count: equipped_items.size}
      end

      private

      def valid_slot?(slot)
        ItemTemplate::EQUIPMENT_SLOTS.include?(slot.to_s)
      end

      def equipped_in_slot(slot)
        exact = equipped_in_exact_slot(slot)
        return exact if exact

        return unless slot.to_s == "off_hand"

        main_hand = equipped_in_exact_slot(:main_hand)
        main_hand if main_hand&.two_handed?
      end

      def target_slot_for(item)
        candidates = slot_candidates(item.item_template)
        candidates.find { |candidate| equipped_in_slot(candidate).blank? } || candidates.first
      end

      def slot_candidates(template)
        case template.slot.to_s
        when "ring", "ring_1", "ring_2", "ring_3", "ring_4"
          %i[ring_1 ring_2 ring_3 ring_4]
        else
          slot = template.equipment_slot.to_s
          return [] unless valid_slot?(slot)

          [slot.to_sym]
        end
      end

      def equipped_in_exact_slot(slot)
        character.inventory.inventory_items.find_by(equipped: true, equipment_slot: slot)
      end

      def items_to_unequip_for(target_slot, new_item)
        slots = if new_item.two_handed?
          HAND_SLOTS
        else
          [target_slot.to_sym]
        end

        occupied = slots.filter_map { |candidate| equipped_in_exact_slot(candidate) }
        if target_slot.to_sym == :off_hand
          main_hand = equipped_in_exact_slot(:main_hand)
          occupied << main_hand if main_hand&.two_handed?
        end

        occupied.uniq - [new_item]
      end
    end
  end
end
