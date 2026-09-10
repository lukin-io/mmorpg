# frozen_string_literal: true

module Game
  module Shop
    # Exchanges one offered catalog item for NV. Character/offer, template,
    # inventory, and wallet locks protect price, stock, capacity and replay;
    # goods enter Inventory, typed licenses enter Character Abilities. Every
    # record, shop funds and the consumed offer commit together. The wallet
    # receipt records the acquired entity and both sides of the settlement.
    class Purchase
      Result = Struct.new(:success, :message, :item, keyword_init: true)

      def initialize(character:, item_template:, action_key:, quantity: 1)
        @character = character
        @item_template = item_template
        @action_key = action_key
        @quantity = quantity
      end

      def call
        return failure("Buy one item at a time.") unless quantity.to_s == "1"
        return failure("This item cannot be bought.") unless item_template

        offers = TradeOffers.new(character:)
        offers.perform(action_key:, action: :buy, target: item_template) do |offer, account|
          item_template.lock!
          reject!("This item cannot be bought.") unless item_template.available_in_shop?
          offers.validate_target!(offer, item_template)
          stock = account.shop_stocks.lock.find_by(item_template:)
          reject!("This item cannot be bought.") unless stock
          reject!("Out of stock.") if stock.out_of_stock?

          inventory.lock!
          wallet.lock!
          license_rules = LicenseRules.new(character:)
          license_block_reason = license_rules.purchase_block_reason(item_template)
          reject!(license_block_reason) if license_block_reason
          if account.nv_balance + item_template.base_price >= ShopAccount::NV_LIMIT
            reject!("The Shop cannot receive this payment right now.")
          end
          reject!("Not enough NV.") if wallet.nv_balance < item_template.base_price
          offers.validate_deadline!(offer)

          weight_before = inventory.current_weight
          acquired = if LicenseRules.definition(item_template)
            license_rules.activate!(template: item_template, offer:)
          else
            Game::Inventory::Manager.new(inventory:).add_item!(item_template:, quantity: 1)
          end
          owned_item = acquired if acquired.is_a?(InventoryItem)
          wallet.adjust!(
            amount: -item_template.base_price,
            reason: "shop.purchase",
            metadata: {
              "receipt_version" => 1,
              "character_id" => character.id,
              "item_template_id" => item_template.id,
              "item_template_key" => item_template.key,
              "item" => item_template.name,
              "quantity" => 1,
              "shop_offer_id" => offer.id,
              "shop_account_id" => account.id,
              "shop_stock_id" => stock.id,
              "unit_price" => format("%.2f", item_template.base_price),
              "wallet_balance_before" => format("%.2f", wallet.nv_balance),
              "wallet_balance_after" => format("%.2f", wallet.nv_balance - item_template.base_price),
              "shop_balance_before" => format("%.2f", account.nv_balance),
              "shop_balance_after" => format("%.2f", account.nv_balance + item_template.base_price),
              "shop_stock_before" => stock.current,
              "shop_stock_after" => stock.current - 1,
              "inventory_item_id" => owned_item&.id,
              "inventory_quantity_before" => owned_item && owned_item.quantity - 1,
              "inventory_quantity_after" => owned_item&.quantity,
              "inventory_weight_before" => weight_before,
              "inventory_weight_after" => inventory.current_weight,
              "character_license_id" => acquired.is_a?(CharacterLicense) ? acquired.id : nil
            }.compact
          )
          account.update!(nv_balance: account.nv_balance + item_template.base_price)
          stock.update!(current: stock.current - 1)
        end

        Result.new(success: true, message: "Bought: #{item_template.name}.", item: item_template)
      rescue TradeOffers::Unavailable, Game::Inventory::Manager::CapacityExceededError => e
        failure(e.message)
      rescue Economy::WalletService::InsufficientFundsError
        failure("Not enough NV.")
      rescue ActiveRecord::RecordNotFound
        failure("This item is no longer available.")
      end

      private

      attr_reader :character, :item_template, :action_key, :quantity

      def inventory
        @inventory ||= character.inventory || character.create_inventory!
      end

      def wallet
        @wallet ||= character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
      end

      def reject!(message)
        raise TradeOffers::Unavailable, message
      end

      def failure(message)
        Result.new(success: false, message:, item: item_template)
      end
    end
  end
end
