# frozen_string_literal: true

module Game
  module Inventory
    # Manager enforces slot/weight limits plus stack handling for character inventories.
    #
    # Purpose: Manages inventory operations including adding/removing items, stacking,
    #          using consumables, and sorting.
    #
    # Instance Usage:
    #   Game::Inventory::Manager.new(inventory:).add_item!(item_template:, quantity: 5)
    #
    # Class Method Usage:
    #   Game::Inventory::Manager.use_item(character, inventory_item)
    #   Game::Inventory::Manager.sort_inventory!(inventory, by: :type)
    #
    # Returns:
    #   InventoryItem (stack) that received the change.
    class Manager
      # Use a consumable item from inventory
      #
      # @param character [Character] the character using the item
      # @param inventory_item [InventoryItem] the item to use
      # @return [Hash] result with :success, :message or :error keys
      def self.use_item(character, inventory_item)
        template = inventory_item.item_template

        unless template.consumable?
          return {success: false, error: "This item cannot be used"}
        end

        result = apply_item_effect(character, template)
        return result unless result[:success]

        # Decrease quantity or remove item
        if inventory_item.quantity > 1
          inventory_item.decrement!(:quantity)
        else
          inventory_item.destroy!
        end

        result
      end

      # Sort inventory items by specified criteria
      #
      # @param inventory [Inventory] the inventory to sort
      # @param by [Symbol] sort criteria (:type, :rarity, :name)
      # @return [void]
      def self.sort_inventory!(inventory, by: :type)
        items = inventory.inventory_items.includes(:item_template).to_a

        sorted = case by
        when :type
          items.sort_by { |i| [i.item_template.item_type || "", i.item_template.name] }
        when :rarity
          rarity_order = %w[legendary epic rare uncommon common]
          items.sort_by { |i| [rarity_order.index(i.item_template.rarity) || 99, i.item_template.name] }
        when :name
          items.sort_by { |i| i.item_template.name }
        else
          items
        end

        sorted.each_with_index do |item, index|
          item.update_column(:slot_index, index)
        end
      end

      # Apply item effect based on item type
      #
      # @param character [Character] the character to apply effect to
      # @param template [ItemTemplate] the item template with effect data
      # @return [Hash] result with :success and :message or :error
      def self.apply_item_effect(character, template)
        stats = template.stat_modifiers || {}

        if stats["heal_hp"]
          amount = stats["heal_hp"].to_i
          actual_healed = Characters::VitalsService.new(character).apply_healing(amount, source: template.name)
          return {success: true, message: "Restored #{actual_healed} HP"}
        end

        if stats["restore_mp"]
          amount = stats["restore_mp"].to_i
          actual_restored = Characters::VitalsService.new(character).restore_mana(amount, source: template.name)
          return {success: true, message: "Restored #{actual_restored} MP"}
        end

        if stats["heal_hp_percent"]
          percent = stats["heal_hp_percent"].to_f / 100.0
          amount = (character.max_hp * percent).to_i
          actual_healed = Characters::VitalsService.new(character).apply_healing(amount, source: template.name)
          return {success: true, message: "Restored #{actual_healed} HP"}
        end

        # Default case - item has no known effect
        {success: false, error: "Item has no usable effect"}
      end

      private_class_method :apply_item_effect

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

          if stack.new_record?
            # New stack - set quantity directly and save
            stack.quantity = to_add
            stack.save!
          else
            # Existing stack - increment
            stack.increment!(:quantity, to_add)
          end
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
        # Build (don't save yet) - caller will set quantity and save
        inventory.inventory_items.build(
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
