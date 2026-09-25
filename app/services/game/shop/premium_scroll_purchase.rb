# frozen_string_literal: true

module Game
  module Shop
    # Buys Ashen premium scrolls for Veil Marks (hospital desk / inventory panel).
    class PremiumScrollPurchase
      Result = Struct.new(:success, :message, keyword_init: true)
      OFFERINGS = {
        "assault_scroll_peaceful" => 8,
        "assault_scroll_normal" => 15,
        "assault_scroll_bloody" => 35,
        "protection_scroll" => 25,
        "combat_heal_scroll" => 20,
        # Legacy key kept buyable as Bloody alias for older UI/tests.
        "combat_trauma_scroll" => 35
      }.freeze

      def self.owned_quantity(character, item_key)
        Game::Combat::AssaultScrolls.quantity(character, item_key)
      end

      def initialize(character:, item_key:)
        @character = character
        @item_key = item_key.to_s
      end

      def call
        price = OFFERINGS[item_key]
        return failure(I18n.t("game.buildings.premium_unknown")) unless price

        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: item_key)
        return failure(I18n.t("game.buildings.premium_unknown")) unless template

        character.with_lock do
          character.reload
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0, veil_marks: 0)
          begin
            wallet.adjust_veil_marks!(
              amount: -price,
              reason: "ashen.premium_scroll",
              metadata: {"item_key" => item_key, "character_id" => character.id}
            )
          rescue Economy::WalletService::InsufficientFundsError
            return failure(I18n.t("game.buildings.premium_short", amount: price))
          end

          inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
          Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: 1)
          Result.new(
            success: true,
            message: I18n.t("game.buildings.premium_bought", name: template.name, amount: price)
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("CapacityExceededError")

        failure(I18n.t("game.inventory.craft_inventory_full"))
      end

      private

      attr_reader :character, :item_key

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
