# frozen_string_literal: true

module Game
  module World
    # Souvenir counter: buy small Ashen materials for NV without a trading license.
    class SouvenirPurchase
      Result = Struct.new(:success, :message, keyword_init: true)
      BASE_OFFERINGS = {
        "ashen_bait" => 8,
        "wood_chips" => 3,
        "ash_herb" => 5,
        "rat_tail" => 5,
        "ashen_hatchet" => 45,
        "ashen_sickle" => 40,
        "ashen_fishing_rod" => 55,
        "ashen_rod_ash" => 120,
        "ashen_rod_salt" => 220,
        "ashen_rod_veil" => 400,
        "hook_worm" => 3,
        "hook_bloodworm" => 5,
        "hook_dough" => 4,
        "hook_ember_fly" => 7,
        "hook_crumb" => 2
      }.freeze

      def self.offerings
        potions = Game::Professions::PotionCatalog::POTIONS.keys.index_with do |key|
          Game::Professions::PotionCatalog.shop_price(key)
        end
        BASE_OFFERINGS.merge(potions)
      end

      OFFERINGS = BASE_OFFERINGS # legacy constant; prefer offerings

      def initialize(character:, item_key:)
        @character = character
        @item_key = item_key.to_s
      end

      def call
        price = self.class.offerings[item_key]
        return failure(I18n.t("game.buildings.souvenir_unknown")) unless price

        character.with_lock do
          character.reload
          Game::Professions::Templates.ensure_craft_items!
          Game::World::FishingCatalog.ensure_templates!
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.buildings.souvenir_unknown")) unless template

          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          if wallet.nv_balance.to_i < price
            return failure(I18n.t("game.buildings.souvenir_short", amount: price))
          end

          inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
          wallet.adjust!(
            amount: -price,
            reason: "ashen.souvenir_buy",
            metadata: {"item_key" => item_key}
          )
          Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: 1)
          Result.new(
            success: true,
            message: I18n.t("game.buildings.souvenir_bought", name: template.display_name, amount: price)
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("CapacityExceededError")

        failure(I18n.t("game.buildings.souvenir_full"))
      end

      private

      attr_reader :character, :item_key

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
