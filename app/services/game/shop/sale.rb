# frozen_string_literal: true

module Game
  module Shop
    # Sells inventory item stacks back to the city shop.
    class Sale
      Result = Struct.new(:success, :message, :item, keyword_init: true)

      def initialize(character:, inventory_item:, quantity:)
        @character = character
        @inventory_item = inventory_item
        @quantity = quantity.to_i
      end

      def call
        return failure("Item not found.") unless inventory_item
        return failure("Invalid quantity.") unless quantity.positive?
        return failure("Not enough items in stack.") if quantity > inventory_item.quantity.to_i
        return failure("This item cannot be sold.") if inventory_item.protected_from_discard?
        return failure("This item cannot be sold.") unless unit_price.positive?

        ApplicationRecord.transaction do
          inventory.lock!
          inventory_item.lock!
          remove_quantity!
          wallet.adjust!(
            amount: total_price,
            reason: "shop.sale",
            metadata: {
              "item_template_id" => template.id,
              "item" => template.name,
              "quantity" => quantity
            }
          )
        end

        Result.new(success: true, message: "Sold: #{template.name} x#{quantity}.", item: inventory_item)
      end

      private

      attr_reader :character, :inventory_item, :quantity

      def template
        @template ||= inventory_item.item_template
      end

      def inventory
        @inventory ||= character.inventory
      end

      def wallet
        @wallet ||= character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
      end

      def unit_price
        @unit_price ||= Game::Shop::Catalog.sale_price(template)
      end

      def total_price
        unit_price * quantity
      end

      def remove_quantity!
        if inventory_item.quantity > quantity
          inventory_item.decrement!(:quantity, quantity)
        else
          inventory_item.destroy!
        end

        removed_weight = inventory_item.weight.to_i * quantity
        inventory.update!(current_weight: [inventory.current_weight.to_i - removed_weight, 0].max)
      end

      def failure(message)
        Result.new(success: false, message:, item: inventory_item)
      end
    end
  end
end
