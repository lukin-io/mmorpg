# frozen_string_literal: true

module Game
  module Shop
    # Exchanges one owned offered item for its current durability-adjusted NV
    # value. Uses the same template -> inventory -> wallet lock order as Buy,
    # and validates item state only after locking its authoritative records.
    # The wallet receipt preserves both balances, stock and removed-item state.
    class Sale
      Result = Struct.new(:success, :message, :item, keyword_init: true)

      def initialize(character:, inventory_item:, action_key:, quantity: 1)
        @character = character
        @inventory_item = inventory_item
        @action_key = action_key
        @quantity = quantity
      end

      def call
        return failure(I18n.t("game.shop.sell_one_at_a_time")) unless quantity.to_s == "1"
        return failure(I18n.t("game.inventory.item_not_found")) unless inventory_item && inventory_item.inventory_id == character.inventory&.id

        offers = TradeOffers.new(character:)
        offers.perform(action_key:, action: :sell, target: inventory_item) do |offer, account|
          template.lock!
          stock = account.shop_stocks.lock.find_by(item_template: template)
          reject!(I18n.t("game.shop.not_accepted")) unless stock
          reject!(I18n.t("game.shop.shop_full")) unless stock.accepts_return?
          inventory.lock!
          inventory_item.lock!
          wallet.lock!
          reject!(I18n.t("game.shop.sell_trading_license_required")) unless LicenseRules.new(character:).active?(:trading)
          reject!(I18n.t("game.inventory.item_not_found")) unless inventory_item.inventory_id == inventory.id
          reject!(I18n.t("game.shop.not_enough_in_stack")) unless inventory_item.quantity.positive?
          reject!(I18n.t("game.shop.cannot_be_sold")) if inventory_item.protected_from_discard?
          reject!(I18n.t("game.shop.invalid_sale_durability")) unless inventory_item.valid_sale_durability?
          reject!(I18n.t("game.shop.broken_cannot_sell")) if inventory_item.broken?
          offers.validate_target!(offer, inventory_item)
          trading_skill = LicenseRules.trading_skill(character)
          unit_price = Catalog.sale_price_for_item(inventory_item, trading_skill:)
          reject!(I18n.t("game.shop.cannot_be_sold")) unless unit_price.positive?
          reject!(I18n.t("game.shop.shop_no_nv")) if account.nv_balance < unit_price
          if wallet.nv_balance + unit_price >= CurrencyWallet::NV_STORAGE_LIMIT
            reject!(I18n.t("game.shop.wallet_payment_blocked"))
          end

          offers.validate_deadline!(offer)
          quantity_before = inventory_item.quantity
          weight_before = inventory.current_weight
          remove_unit!
          wallet.adjust!(
            amount: unit_price,
            reason: "shop.sale",
            metadata: {
              "receipt_version" => 1,
              "character_id" => character.id,
              "item_template_id" => template.id,
              "item_template_key" => template.key,
              "item" => template.name,
              "quantity" => 1,
              "shop_offer_id" => offer.id,
              "shop_account_id" => account.id,
              "shop_stock_id" => stock.id,
              "unit_price" => format("%.2f", unit_price),
              "base_price" => format("%.2f", template.base_price),
              "wallet_balance_before" => format("%.2f", wallet.nv_balance),
              "wallet_balance_after" => format("%.2f", wallet.nv_balance + unit_price),
              "shop_balance_before" => format("%.2f", account.nv_balance),
              "shop_balance_after" => format("%.2f", account.nv_balance - unit_price),
              "trading_skill" => trading_skill,
              "current_durability" => inventory_item.current_durability,
              "max_durability" => inventory_item.max_durability,
              "shop_stock_before" => stock.current,
              "shop_stock_after" => stock.current + 1,
              "inventory_item_id" => inventory_item.id,
              "inventory_quantity_before" => quantity_before,
              "inventory_quantity_after" => quantity_before - 1,
              "inventory_weight_before" => weight_before,
              "inventory_weight_after" => inventory.current_weight
            }.compact
          )
          account.update!(nv_balance: account.nv_balance - unit_price)
          stock.update!(current: stock.current + 1)
        end

        Result.new(success: true, message: I18n.t("game.shop.sold", name: template.name), item: inventory_item)
      rescue TradeOffers::Unavailable => e
        failure(e.message)
      rescue ActiveRecord::RecordNotFound
        failure(I18n.t("game.shop.item_unavailable"))
      end

      private

      attr_reader :character, :inventory_item, :action_key, :quantity

      def template
        @template ||= inventory_item.item_template
      end

      def inventory
        @inventory ||= character.inventory
      end

      def wallet
        @wallet ||= character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
      end

      def remove_unit!
        if inventory_item.quantity > 1
          inventory_item.decrement!(:quantity)
        else
          inventory_item.destroy!
        end

        inventory.update!(current_weight: [inventory.current_weight - inventory_item.weight, 0].max)
      end

      def reject!(message)
        raise TradeOffers::Unavailable, message
      end

      def failure(message)
        Result.new(success: false, message:, item: inventory_item)
      end
    end
  end
end
