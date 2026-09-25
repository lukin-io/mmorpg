# frozen_string_literal: true

module Game
  module World
    # Ashen Resource Exchange — instant settlement at Neverlands government
    # prices (Викиневер: биржа / шахтёр). Full 4h auction matching remains a
    # deeper parity track; sell/buy/storage here close the lobby [IMPL] gap.
    class ResourceExchange
      Result = Struct.new(:success, :message, :paid, :spent, keyword_init: true)

      # Government NV/unit from wiki (ores & coal). Soft-release keys map to
      # those rows; herbs/fish reuse JunkBuyback floors so shore materials clear.
      GOV_PRICES = {
        "coal_chunk" => 20,
        "iron_ore" => 25,
        "silver_ore" => 30,
        "ash_crystal" => 60,
        "wood_chips" => 1,
        "pine_resin" => 3,
        "ash_oak_plank" => 4,
        "veil_willow_bark" => 2,
        "soot_birch_sap" => 3,
        "ember_cedar_plank" => 5,
        "drift_alder_wood" => 3,
        "ash_herb" => 3,
        "dust_moss" => 2,
        "glow_lichen" => 4,
        "ember_fern" => 3,
        "salt_sage" => 3,
        "veil_bloom" => 5,
        "cinder_root" => 3,
        "tar_needle" => 3,
        "mist_leaf" => 4,
        "nightshade_ash" => 6,
        "ember_cap" => 4,
        "silver_thistle" => 5,
        "moon_orchid" => 8,
        "ash_perch" => 9,
        "veil_eel" => 16,
        "salt_carp" => 12,
        "ember_trout" => 22,
        "drift_smelt" => 5,
        "cinder_pike" => 18,
        "mist_roach" => 6,
        "veil_blackfin" => 20,
        "glass_minnow" => 4
      }.freeze

      BUY_MARKUP = 1.1
      STORAGE_KEY = "resource_exchange_storage"
      STORAGE_CAP = 200

      CATEGORY_KEYS = {
        "Fish resources" => %w[ash_perch veil_eel salt_carp ember_trout drift_smelt cinder_pike mist_roach veil_blackfin glass_minnow],
        "Fish components" => %w[ash_perch mist_roach glass_minnow],
        "Cooking resources" => %w[ash_perch salt_carp ember_trout],
        "Plant resources" => %w[ash_herb dust_moss glow_lichen ember_fern salt_sage veil_bloom cinder_root tar_needle mist_leaf nightshade_ash ember_cap silver_thistle moon_orchid],
        "Alchemy components" => %w[glow_lichen nightshade_ash moon_orchid ash_crystal],
        "Hunting resources" => %w[ember_fern cinder_root],
        "Hunting alchemy components" => %w[ember_cap nightshade_ash],
        "Mineral resources" => %w[coal_chunk iron_ore silver_ore ash_crystal],
        "Wood" => %w[wood_chips pine_resin ash_oak_plank veil_willow_bark soot_birch_sap ember_cedar_plank drift_alder_wood],
        "Wooden blanks" => %w[ash_oak_plank ember_cedar_plank drift_alder_wood],
        "Firewood" => %w[wood_chips pine_resin],
        "Alloys and metals" => %w[iron_ore silver_ore ash_crystal]
      }.freeze

      def initialize(character:, item_key:, quantity: 1, mode: :sell)
        @character = character
        @item_key = item_key.to_s
        @quantity = [quantity.to_i, 1].max
        @mode = mode.to_sym
      end

      def call
        case mode
        when :sell then sell!
        when :buy then buy!
        when :deposit then deposit!
        when :withdraw then withdraw!
        else
          failure(I18n.t("game.locations.exchange_bad_mode"))
        end
      end

      def self.gov_price(item_key)
        GOV_PRICES[item_key.to_s]
      end

      def self.sell_price(item_key)
        base = gov_price(item_key)
        return nil unless base

        mult = Game::Seasons::Catalog.demand_multiplier(item_key)
        craft = Game::Economy::MistCurve.craft_sell_bonus(item_key)
        (base * mult * craft).round
      end

      def self.buy_price(item_key)
        gov = gov_price(item_key)
        return nil unless gov

        (gov * BUY_MARKUP).ceil
      end

      def self.keys_for_category(category_label)
        CATEGORY_KEYS[category_label.to_s] || GOV_PRICES.keys
      end

      def self.offer_rows_for(character, category: nil)
        keys = category.present? ? keys_for_category(category) : GOV_PRICES.keys
        inventory = character.inventory
        return [] unless inventory

        rows = []
        inventory.inventory_items.includes(:item_template).where(equipped: false).find_each do |row|
          key = row.item_template.key
          next unless keys.include?(key) && GOV_PRICES.key?(key)

          rows << {
            inventory_item_id: row.id,
            item_key: key,
            name: row.item_template.display_name,
            quantity: row.quantity,
            price_each: Game::World::ResourceExchange.sell_price(key) || GOV_PRICES[key],
            total: (Game::World::ResourceExchange.sell_price(key) || GOV_PRICES[key]) * row.quantity
          }
        end
        rows.sort_by { |r| r[:name] }
      end

      def self.buy_catalog(category: nil)
        keys = category.present? ? keys_for_category(category) : GOV_PRICES.keys
        keys.filter_map do |key|
          price = buy_price(key)
          next unless price

          template = ItemTemplate.find_by(key:)
          next unless template

          {item_key: key, name: template.display_name, price_each: price}
        end
      end

      def self.storage_for(character)
        character.metadata.to_h[STORAGE_KEY].to_h.transform_values(&:to_i)
      end

      def self.storage_total(character)
        storage_for(character).values.sum
      end

      private

      attr_reader :character, :item_key, :quantity, :mode

      def sell!
        price_each = self.class.sell_price(item_key)
        return failure(I18n.t("game.locations.exchange_not_accepted")) unless price_each

        character.with_lock do
          character.reload
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.locations.exchange_missing")) unless template

          inventory = character.inventory
          return failure(I18n.t("game.locations.exchange_empty_bag")) unless inventory

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          return failure(I18n.t("game.locations.exchange_not_enough")) if have < quantity

          Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity:)
          paid = price_each * quantity
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          wallet.adjust!(
            amount: paid,
            reason: "ashen.resource_exchange.sell",
            metadata: {"item_key" => item_key, "quantity" => quantity, "gov_price" => price_each}
          )
          Result.new(
            success: true,
            paid:,
            message: I18n.t("game.locations.exchange_sold", name: template.display_name, amount: paid, qty: quantity)
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("InventoryUnderflowError")

        failure(I18n.t("game.locations.exchange_not_enough"))
      end

      def buy!
        price_each = self.class.buy_price(item_key)
        return failure(I18n.t("game.locations.exchange_not_accepted")) unless price_each

        character.with_lock do
          character.reload
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.locations.exchange_missing")) unless template

          spent = price_each * quantity
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          return failure(I18n.t("game.shop.not_enough_nv")) if wallet.nv_balance.to_d < spent

          inventory = character.inventory || character.create_inventory!
          wallet.adjust!(
            amount: -spent,
            reason: "ashen.resource_exchange.buy",
            metadata: {"item_key" => item_key, "quantity" => quantity, "buy_price" => price_each}
          )
          Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity:)
          Result.new(
            success: true,
            spent:,
            message: I18n.t("game.locations.exchange_bought", name: template.display_name, amount: spent, qty: quantity)
          )
        end
      rescue Game::Inventory::Manager::CapacityExceededError => e
        failure(e.message)
      end

      def deposit!
        return failure(I18n.t("game.locations.exchange_not_accepted")) unless self.class.gov_price(item_key)

        character.with_lock do
          character.reload
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.locations.exchange_missing")) unless template

          inventory = character.inventory
          return failure(I18n.t("game.locations.exchange_empty_bag")) unless inventory

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          return failure(I18n.t("game.locations.exchange_not_enough")) if have < quantity

          stored = self.class.storage_for(character)
          return failure(I18n.t("game.locations.exchange_storage_full", cap: STORAGE_CAP)) if stored.values.sum + quantity > STORAGE_CAP

          Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity:)
          stored[item_key] = stored[item_key].to_i + quantity
          meta = character.metadata.to_h.merge(STORAGE_KEY => stored)
          character.update!(metadata: meta)
          Result.new(
            success: true,
            message: I18n.t("game.locations.exchange_deposited", name: template.display_name, qty: quantity)
          )
        end
      rescue StandardError => error
        raise unless error.class.name.end_with?("InventoryUnderflowError")

        failure(I18n.t("game.locations.exchange_not_enough"))
      end

      def withdraw!
        character.with_lock do
          character.reload
          template = ItemTemplate.find_by(key: item_key)
          return failure(I18n.t("game.locations.exchange_missing")) unless template

          stored = self.class.storage_for(character)
          have = stored[item_key].to_i
          return failure(I18n.t("game.locations.exchange_storage_empty")) if have < quantity

          inventory = character.inventory || character.create_inventory!
          Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity:)
          stored[item_key] = have - quantity
          stored.delete(item_key) if stored[item_key] <= 0
          meta = character.metadata.to_h.merge(STORAGE_KEY => stored)
          character.update!(metadata: meta)
          Result.new(
            success: true,
            message: I18n.t("game.locations.exchange_withdrawn", name: template.display_name, qty: quantity)
          )
        end
      rescue Game::Inventory::Manager::CapacityExceededError => e
        failure(e.message)
      end

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
