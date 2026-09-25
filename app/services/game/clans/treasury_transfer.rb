# frozen_string_literal: true

module Game
  module Clans
    # Donate unequipped inventory stacks or NV into the clan treasury.
    # Withdraw respects lock + role rules (see Clan#can_withdraw_treasury?).
    class TreasuryTransfer
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:, action:, item_key: nil, quantity: 1, amount_nv: 0, treasury_item_id: nil)
        @actor = actor
        @action = action.to_s
        @item_key = item_key.to_s
        @quantity = [quantity.to_i, 1].max
        @amount_nv = amount_nv.to_d
        @treasury_item_id = treasury_item_id
      end

      def call
        membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless membership

        @clan = membership.clan
        case action
        when "donate_item" then donate_item!
        when "donate_nv" then donate_nv!
        when "withdraw_item" then withdraw_item!
        when "withdraw_nv" then withdraw_nv!
        else
          fail!(I18n.t("game.clans.treasury_bad_action"))
        end
      end

      private

      attr_reader :actor, :action, :item_key, :quantity, :amount_nv, :treasury_item_id, :clan

      def donate_item!
        return fail!(I18n.t("game.clans.treasury_donate_denied")) unless clan.can_donate?(actor)
        return fail!(I18n.t("game.fight.inventory_locked")) if actor.in_combat?

        template = ItemTemplate.find_by(key: item_key)
        return fail!(I18n.t("game.clans.treasury_item_missing")) unless template

        actor.with_lock do
          clan.lock!
          inventory = actor.inventory
          return fail!(I18n.t("game.clans.treasury_empty_bag")) unless inventory

          have = inventory.inventory_items.where(item_template: template, equipped: false).sum(:quantity)
          return fail!(I18n.t("game.clans.treasury_short")) if have < quantity

          Game::Inventory::Manager.new(inventory:).remove_item!(item_template: template, quantity:)
          row = clan.clan_treasury_items.find_or_initialize_by(item_template: template)
          row.quantity = row.quantity.to_i + quantity
          row.deposited_by_character = actor
          row.save!
        end
        Result.new(success: true, message: I18n.t("game.clans.treasury_donated_item", name: template.display_name, qty: quantity))
      end

      def donate_nv!
        return fail!(I18n.t("game.clans.treasury_donate_denied")) unless clan.can_donate?(actor)
        return fail!(I18n.t("game.clans.treasury_nv_invalid")) unless amount_nv.positive?

        wallet = actor.user.currency_wallet
        return fail!(I18n.t("game.clans.treasury_nv_short")) unless wallet && wallet.nv_balance >= amount_nv

        ActiveRecord::Base.transaction do
          actor.with_lock do
            clan.lock!
            wallet.lock!
            wallet.adjust!(amount: -amount_nv, reason: "clan.treasury_donate")
            clan.update!(treasury_nv: clan.treasury_nv + amount_nv)
          end
        end
        Result.new(success: true, message: I18n.t("game.clans.treasury_donated_nv", amount: amount_nv.to_i))
      end

      def withdraw_item!
        return fail!(I18n.t("game.clans.treasury_withdraw_denied")) unless clan.can_withdraw_treasury?(actor)
        return fail!(I18n.t("game.clans.treasury_is_locked")) if clan.treasury_locked? && !%w[leader treasurer].include?(clan.role_of(actor))
        return fail!(I18n.t("game.fight.inventory_locked")) if actor.in_combat?

        actor.with_lock do
          clan.lock!
          row = clan.clan_treasury_items.find_by(id: treasury_item_id)
          return fail!(I18n.t("game.clans.treasury_item_missing")) unless row
          return fail!(I18n.t("game.clans.treasury_short")) if row.quantity < quantity

          inventory = actor.inventory || actor.create_inventory!
          begin
            Game::Inventory::Manager.new(inventory:).add_item!(item_template: row.item_template, quantity:)
          rescue StandardError
            return fail!(I18n.t("game.clans.treasury_capacity"))
          end

          if row.quantity == quantity
            row.destroy!
          else
            row.update!(quantity: row.quantity - quantity)
          end
        end
        Result.new(success: true, message: I18n.t("game.clans.treasury_withdrew_item", qty: quantity))
      end

      def withdraw_nv!
        return fail!(I18n.t("game.clans.treasury_withdraw_denied")) unless clan.can_withdraw_treasury?(actor)
        return fail!(I18n.t("game.clans.treasury_is_locked")) if clan.treasury_locked? && !%w[leader treasurer].include?(clan.role_of(actor))
        return fail!(I18n.t("game.clans.treasury_nv_invalid")) unless amount_nv.positive?

        ActiveRecord::Base.transaction do
          actor.with_lock do
            clan.lock!
            return fail!(I18n.t("game.clans.treasury_nv_short")) if clan.treasury_nv < amount_nv

            wallet = actor.user.currency_wallet || actor.user.create_currency_wallet!(nv_balance: 0)
            wallet.lock!
            clan.update!(treasury_nv: clan.treasury_nv - amount_nv)
            wallet.adjust!(amount: amount_nv, reason: "clan.treasury_withdraw")
          end
        end
        Result.new(success: true, message: I18n.t("game.clans.treasury_withdrew_nv", amount: amount_nv.to_i))
      end

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
