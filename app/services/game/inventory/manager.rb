# frozen_string_literal: true

module Game
  module Inventory
    # Manager enforces slot/weight limits plus stack handling for character inventories.
    #
    # Usage:
    #   Game::Inventory::Manager.new(inventory:).add_item!(item_template:, quantity: 5)
    #
    # Returns:
    #   InventoryItem (stack) that received the change.
    class Manager
      def initialize(inventory:)
        @inventory = inventory
      end

      def add_item!(item_template:, quantity: 1, premium: false)
        remaining = quantity
        last_stack = nil

        while remaining.positive?
          stack = find_or_build_stack(item_template:, premium:)
          capacity = item_template.stack_limit - stack.quantity
          raise CapacityExceededError, "Stack limit reached" if capacity <= 0

          to_add = [remaining, capacity].min
          ensure_weight_capacity!(item_template.weight * to_add)

          stack.increment!(:quantity, to_add)
          increment_weight!(item_template.weight * to_add)
          remaining -= to_add
          last_stack = stack
        end

        last_stack
      end

      def remove_item!(item_template:, quantity: 1)
        remaining = quantity
        inventory.inventory_items.where(item_template:).order(:created_at).each do |stack|
          break if remaining <= 0

          to_remove = [remaining, stack.quantity].min
          stack.decrement!(:quantity, to_remove)
          decrement_weight!(stack.weight * to_remove)
          remaining -= to_remove
          stack.destroy if stack.quantity.zero?
        end

        raise InventoryUnderflowError, "Not enough items" if remaining.positive?
      end

      private

      class CapacityExceededError < StandardError; end
      class InventoryUnderflowError < StandardError; end

      attr_reader :inventory

      def find_or_build_stack(item_template:, premium:)
        stack = inventory.inventory_items.where(item_template:, equipped: false, premium:).order(:created_at).detect do |existing|
          existing.quantity < item_template.stack_limit
        end
        return stack if stack

        ensure_slot_capacity!
        inventory.inventory_items.create!(
          item_template:,
          quantity: 0,
          weight: item_template.weight,
          premium:
        )
      end

      def ensure_slot_capacity!
        used_slots = inventory.inventory_items.count
        raise CapacityExceededError, "No inventory slots available" if used_slots >= inventory.slot_capacity
      end

      def ensure_weight_capacity!(delta)
        projected = inventory.current_weight + delta
        raise CapacityExceededError, "Inventory overweight" if projected > inventory.weight_capacity
      end

      def increment_weight!(delta)
        inventory.increment!(:current_weight, delta)
      end

      def decrement_weight!(delta)
        inventory.decrement!(:current_weight, delta)
      end
    end
  end
end
