# frozen_string_literal: true

module Game
  module Shop
    # License-free Ashen junk buyback for craft materials and surplus T5 drops.
    class JunkBuyback
      Result = Struct.new(:success, :message, :paid, keyword_init: true)

      PRICES = {
        "wood_chips" => 1,
        "rat_tail" => 3,
        "ashen_bait" => 2,
        "ashen_bandage" => 8,
        "ash_herb" => 3,
        "ash_perch" => 9,
        "mist_roach" => 6,
        "veil_eel" => 16,
        "salt_carp" => 12,
        "ember_trout" => 22,
        "cinder_pike" => 18,
        "drift_smelt" => 5,
        "grilled_ash_perch" => 18,
        "veil_fish_stew" => 48,
        "smoked_cinder_pike" => 36,
        "mist_roach_cakes" => 16,
        "pike_broth" => 28,
        "salt_elixir" => 32,
        "ember_salve" => 30,
        "ash_tonic" => 12,
        "healer_bag_light" => 22,
        "veil_field_kit" => 45,
        "hook_worm" => 1,
        "hook_bloodworm" => 2,
        "hook_dough" => 1,
        "hook_ember_fly" => 2,
        "hook_crumb" => 1,
        "pine_resin" => 3,
        "ember_fern" => 3,
        "dust_moss" => 2,
        "salt_sage" => 3,
        "veil_willow_bark" => 2,
        "cinder_root" => 3
      }.freeze

      T5_SET_PRICE = 8
      T5_SET_PATTERN = /\Aset-.+-t5\z/

      def initialize(character:, item_key:, quantity: 1)
        @character = character
        @item_key = item_key.to_s
        @quantity = [quantity.to_i, 1].max
      end

      def call
        price_each = price_for(item_key)
        return failure(I18n.t("game.buildings.junk_not_accepted")) unless price_each

        character.with_lock do
          character.reload
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.buildings.junk_item_missing")) unless template

          inventory = character.inventory
          return failure(I18n.t("game.buildings.junk_inventory_empty")) unless inventory

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          return failure(I18n.t("game.buildings.junk_not_enough")) if have < quantity

          Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity:)
          paid = price_each * quantity
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          wallet.adjust!(
            amount: paid,
            reason: "ashen.junk_buyback",
            metadata: {"item_key" => item_key, "quantity" => quantity}
          )

          Result.new(
            success: true,
            paid:,
            message: I18n.t("game.buildings.junk_sold", name: template.display_name, amount: paid, qty: quantity)
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("InventoryUnderflowError")

        failure(I18n.t("game.buildings.junk_not_enough"))
      end

      def self.price_for(item_key)
        key = item_key.to_s
        return PRICES[key] if PRICES.key?(key)
        return T5_SET_PRICE if key.match?(T5_SET_PATTERN)

        nil
      end

      def self.offer_rows_for(character)
        inventory = character.inventory
        return [] unless inventory

        rows = []
        PRICES.each do |key, price|
          template = ItemTemplate.find_by(key:)
          next unless template

          qty = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          next if qty <= 0

          rows << {key:, name: template.display_name, quantity: qty, price:}
        end

        t5_qty = Hash.new(0)
        t5_names = {}
        inventory.inventory_items.includes(:item_template).where(equipped: false).find_each do |row|
          key = row.item_template.key
          next if PRICES.key?(key)
          next unless key.match?(T5_SET_PATTERN)

          t5_qty[key] += row.quantity
          t5_names[key] = row.item_template.display_name
        end
        t5_qty.each do |key, qty|
          rows << {key:, name: t5_names[key], quantity: qty, price: T5_SET_PRICE}
        end

        rows
      end

      private

      attr_reader :character, :item_key, :quantity

      def price_for(key)
        self.class.price_for(key)
      end

      def failure(message)
        Result.new(success: false, message:, paid: 0)
      end
    end
  end
end
