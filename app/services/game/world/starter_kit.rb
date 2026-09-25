# frozen_string_literal: true

module Game
  module World
    # One-time Ashen sandbox starter kit for a newly created character.
    # Grants bait, starter NV, and a free equipped blade so the shore loop is
    # reachable without an empty wallet or bare fists.
    class StarterKit
      METADATA_KEY = "ashen_starter_kit_v5"
      LEGACY_METADATA_KEYS = %w[ashen_starter_kit_v1 ashen_starter_kit_v2 ashen_starter_kit_v3 ashen_starter_kit_v4].freeze
      STARTER_NV = 100
      STARTER_VEIL_MARKS = 40
      NV_REASON = "ashen.starter_kit_nv"
      VM_REASON = "ashen.starter_kit_veil_marks"
      WEAPON_KEY = "ashen_starter_blade"
      # Keep craft mats inside a level-0 carrying capacity (~15) after bait+blade+bandage+herbs.
      CRAFT_MATS = {
        "wood_chips" => 3,
        "rat_tail" => 2
      }.freeze
      STARTER_BANDAGE = 1
      BANDAGE_KEY = "ashen_bandage"
      STARTER_HERB = 2
      HERB_KEY = "ash_herb"

      def initialize(character:)
        @character = character
      end

      def call
        character.with_lock do
          character.reload
          grant_weapon!
          grant_bait!
          grant_craft_mats!
          grant_bandage!
          grant_herbs!
          grant_starter_nv!
          grant_starter_veil_marks! if Game::Shop::PremiumGateway.stub_iap_allowed?
          mark_granted!
        end

        character
      end

      def self.ensure_weapon_template!
        ItemTemplate.find_or_initialize_by(key: WEAPON_KEY).tap do |item|
          item.assign_attributes(
            name: "Клинок Угля",
            item_type: "equipment",
            slot: "main_hand",
            weight: 2,
            stack_limit: 1,
            base_price: 1,
            durability_max: 40,
            requirements: {},
            stat_modifiers: {"attack" => 3, "accuracy" => 2},
            enhancement_rules: {
              "inventory_family" => "weapons",
              "subcategory" => "swords",
              "source_name" => "Клинок Угля",
              "description" => "Стартовый клинок Пепельной Завесы.",
              "shop" => {"sold" => true, "mode" => "buy", "position" => 5},
              "shop_stock" => {"current" => 200, "max" => 200}
            }
          )
          item.save!
        end
      end

      private

      attr_reader :character

      def grant_bait!
        Game::Professions::Templates.ensure_craft_items!
        template = Bait.item_template
        return unless template

        inventory = ensure_inventory!
        existing = Bait.new(character:).quantity
        need = Bait::STARTER_GRANT - existing
        return if need <= 0

        add_fitting!(inventory:, template:, quantity: need)
      end

      def grant_craft_mats!
        Game::Professions::Templates.ensure_craft_items!
        inventory = ensure_inventory!
        CRAFT_MATS.each do |key, want|
          template = ItemTemplate.find_by(key:)
          next unless template

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          need = want - have
          next unless need.positive?

          add_fitting!(inventory:, template:, quantity: need)
        end
      end

      def grant_bandage!
        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: BANDAGE_KEY)
        return unless template

        inventory = ensure_inventory!
        have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
        need = STARTER_BANDAGE - have
        return unless need.positive?

        add_fitting!(inventory:, template:, quantity: need)
      end

      def grant_herbs!
        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: HERB_KEY)
        return unless template

        inventory = ensure_inventory!
        have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
        need = STARTER_HERB - have
        return unless need.positive?

        add_fitting!(inventory:, template:, quantity: need)
      end

      def ensure_inventory!
        character.inventory || character.create_inventory!(
          slot_capacity: 30,
          weight_capacity: [character.carrying_capacity, 30].max
        )
      end

      # Adds as many units as weight/slot capacity allows. Never raises
      # CapacityExceededError — signup must not 500 over starter loot.
      def add_fitting!(inventory:, template:, quantity:)
        manager = Game::Inventory::Manager.new(inventory:)
        unit_weight = [template.weight.to_i, 1].max
        remaining_weight = [inventory.max_weight.to_i - inventory.current_weight.to_i, 0].max
        can_fit = remaining_weight / unit_weight
        qty = [quantity.to_i, can_fit].min
        return if qty <= 0

        manager.add_item!(item_template: template, quantity: qty)
      rescue StandardError => error
        raise unless error.class.name.end_with?("CapacityExceededError")

        nil
      end

      def grant_starter_nv!
        user = character.user
        return unless user

        wallet = user.currency_wallet || user.create_currency_wallet!(nv_balance: 0)
        wallet.with_lock do
          next if wallet.currency_transactions.where(reason: NV_REASON).exists?

          wallet.adjust!(
            amount: STARTER_NV,
            reason: NV_REASON,
            metadata: {"source" => "ashen_starter_kit", "character_id" => character.id}
          )
        end
      end

      def grant_starter_veil_marks!
        user = character.user
        return unless user

        wallet = user.currency_wallet || user.create_currency_wallet!(nv_balance: 0)
        wallet.with_lock do
          next if wallet.currency_transactions.where(reason: VM_REASON).exists?

          wallet.adjust_veil_marks!(
            amount: STARTER_VEIL_MARKS,
            reason: VM_REASON,
            metadata: {"source" => "ashen_starter_kit", "character_id" => character.id}
          )
        end
      end

      def grant_weapon!
        template = self.class.ensure_weapon_template!
        inventory = ensure_inventory!
        owned = inventory.inventory_items.find_by(item_template: template)
        unless owned
          owned = add_fitting!(inventory:, template:, quantity: 1)
        end
        return unless owned
        return if owned.equipped?

        Game::Inventory::EquipmentService.new(character:, item: owned.reload).equip!
      rescue StandardError => error
        raise unless error.class.name.end_with?("CapacityExceededError")

        nil
      end

      def mark_granted!
        metadata = character.metadata.to_h.except(*LEGACY_METADATA_KEYS)
        character.update!(
          metadata: metadata.merge(
            METADATA_KEY => {
              "granted_at" => Time.current.iso8601(6),
              "bait" => Bait::STARTER_GRANT,
              "nv" => STARTER_NV,
              "veil_marks" => STARTER_VEIL_MARKS,
              "weapon" => WEAPON_KEY,
              "craft_mats" => CRAFT_MATS,
              "bandage" => STARTER_BANDAGE,
              "herbs" => STARTER_HERB
            }
          )
        )
      end
    end
  end
end
