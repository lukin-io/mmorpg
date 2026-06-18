# frozen_string_literal: true

module Game
  module Shop
    # Purchases catalog items into a character inventory with wallet and capacity checks.
    class Purchase
      Result = Struct.new(:success, :message, :item, keyword_init: true)

      def initialize(character:, item_template:, quantity:)
        @character = character
        @item_template = item_template
        @quantity = quantity.to_i
      end

      def call
        return failure("Invalid quantity.") unless quantity.positive?
        return failure("This item cannot be bought.") unless item_template&.base_price.to_i.positive?
        return failure("Нет в наличии.") if item_template.out_of_stock?
        return failure("Not enough stock.") if item_template.shop_stock_limited? && item_template.shop_stock_current.to_i < quantity
        return failure("Not enough NV.") if wallet.nv_balance < total_price

        ApplicationRecord.transaction do
          item_template.lock!
          return failure("Not enough stock.") if item_template.shop_stock_limited? && item_template.shop_stock_current.to_i < quantity

          inventory.lock!
          wallet.adjust!(
            amount: -total_price,
            reason: "shop.purchase",
            metadata: {
              "item_template_id" => item_template.id,
              "item" => item_template.name,
              "quantity" => quantity
            }
          )
          Game::Inventory::Manager.new(inventory:).add_item!(item_template:, quantity:)
          item_template.decrement_shop_stock!(quantity)
        end

        Result.new(success: true, message: "Bought: #{item_template.name} x#{quantity}.", item: item_template)
      rescue Game::Inventory::Manager::CapacityExceededError => e
        failure(e.message)
      rescue Economy::WalletService::InsufficientFundsError
        failure("Not enough NV.")
      end

      private

      attr_reader :character, :item_template, :quantity

      def inventory
        @inventory ||= character.inventory || character.create_inventory!
      end

      def wallet
        @wallet ||= character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
      end

      def total_price
        item_template.base_price.to_i * quantity
      end

      def failure(message)
        Result.new(success: false, message:, item: item_template)
      end
    end
  end
end
