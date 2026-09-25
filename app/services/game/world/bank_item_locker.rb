# frozen_string_literal: true

module Game
  module World
    # Ashen bank: one unequipped item stack in character metadata (NV vault stays separate).
    class BankItemLocker
      Result = Struct.new(:success, :message, keyword_init: true)
      META_KEY = "ashen_bank_item"

      def initialize(character:, action:, item_key: nil, quantity: 1)
        @character = character
        @action = action.to_s
        @item_key = item_key.to_s
        @quantity = [quantity.to_i, 1].max
      end

      def self.stored_for(character)
        raw = character.metadata.to_h[META_KEY]
        return nil unless raw.is_a?(Hash)

        raw.deep_stringify_keys
      end

      def call
        case action
        when "deposit" then deposit!
        when "withdraw" then withdraw!
        else
          Result.new(success: false, message: I18n.t("game.buildings.bank_item_bad_action"))
        end
      end

      private

      attr_reader :character, :action, :item_key, :quantity

      def deposit!
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.bank_item_in_combat"))
          end
          if self.class.stored_for(character).present?
            return Result.new(success: false, message: I18n.t("game.buildings.bank_item_full"))
          end

          Game::Professions::Templates.ensure_craft_items!
          template = ItemTemplate.find_by(key: item_key)
          return Result.new(success: false, message: I18n.t("game.buildings.bank_item_unknown")) unless template

          inventory = character.inventory
          return Result.new(success: false, message: I18n.t("game.buildings.bank_item_empty")) unless inventory

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          if have < quantity
            return Result.new(success: false, message: I18n.t("game.buildings.bank_item_short"))
          end

          Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity:)
          character.update!(
            metadata: character.metadata.to_h.merge(
              META_KEY => {
                "item_key" => template.key,
                "quantity" => quantity,
                "name" => template.display_name,
                "stored_at" => Time.current.iso8601
              }
            )
          )
          Result.new(
            success: true,
            message: I18n.t("game.buildings.bank_item_deposited", name: template.display_name, qty: quantity)
          )
        end
      end

      def withdraw!
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.bank_item_in_combat"))
          end

          stored = self.class.stored_for(character)
          return Result.new(success: false, message: I18n.t("game.buildings.bank_item_none")) unless stored

          Game::Professions::Templates.ensure_craft_items!
          template = ItemTemplate.find_by(key: stored["item_key"])
          return Result.new(success: false, message: I18n.t("game.buildings.bank_item_lost")) unless template

          inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
          begin
            Game::Inventory::Manager.new(inventory:).add_item!(
              item_template: template,
              quantity: stored["quantity"].to_i
            )
          rescue StandardError
            return Result.new(success: false, message: I18n.t("game.buildings.bank_item_capacity"))
          end

          character.update!(metadata: character.metadata.to_h.except(META_KEY))
          Result.new(
            success: true,
            message: I18n.t(
              "game.buildings.bank_item_withdrawn",
              name: template.display_name,
              qty: stored["quantity"].to_i
            )
          )
        end
      end
    end
  end
end
