# frozen_string_literal: true

module Game
  module Seasons
    # Limited-time convenience shop on the season board — better than Mist-style
    # opaque cash shops: every offer is time-saver only (XP, mats, mass), never
    # combat power. Server revalidates season window + one-purchase-per-day caps.
    class Shop
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(character:, offer_key:)
        @character = character
        @offer_key = offer_key.to_s
      end

      def self.offers
        Array(Catalog.current["shop_offers"]).map(&:deep_stringify_keys)
      end

      def self.offer_for(key)
        offers.find { |row| row["key"].to_s == key.to_s }
      end

      def buy!
        return Result.new(success: false, message: I18n.t("game.season.inactive")) unless Catalog.active?

        offer = self.class.offer_for(offer_key)
        return Result.new(success: false, message: I18n.t("game.season.shop_missing")) unless offer

        character.with_lock do
          character.reload
          Progress.new(character:).tap { |p| p.send(:ensure_season!) }
          bag = character.reload.metadata.to_h[Progress::META_KEY].to_h
          purchased = bag.fetch("shop_bought", {}).to_h
          day = Time.current.utc.to_date.iso8601
          day_bag = purchased.fetch(day, {}).to_h
          if offer["once_per_day"] && day_bag[offer_key].present?
            return Result.new(success: false, message: I18n.t("game.season.shop_once_day"))
          end

          price_vm = offer["price_vm"].to_i
          price_nv = offer["price_nv"].to_i
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          if price_vm.positive? && wallet.veil_marks.to_i < price_vm
            return Result.new(success: false, message: I18n.t("game.premium_pass.short_vm", amount: price_vm))
          end
          if price_nv.positive? && wallet.nv_balance.to_d < price_nv
            return Result.new(success: false, message: I18n.t("game.shop.not_enough_nv"))
          end

          if price_vm.positive?
            wallet.adjust_veil_marks!(
              amount: -price_vm,
              reason: "ashen.season.shop",
              metadata: {"offer" => offer_key, "season" => Catalog.current_key}
            )
          end
          if price_nv.positive?
            wallet.adjust!(
              amount: -price_nv,
              reason: "ashen.season.shop",
              metadata: {"offer" => offer_key, "season" => Catalog.current_key}
            )
          end

          grant!(offer.fetch("grant", {}))
          day_bag[offer_key] = Time.current.iso8601
          purchased[day] = day_bag
          bag = character.reload.metadata.to_h[Progress::META_KEY].to_h
          bag["shop_bought"] = purchased
          character.update!(metadata: character.metadata.to_h.merge(Progress::META_KEY => bag))
          Result.new(success: true, message: I18n.t("game.season.shop_bought", name: offer_label(offer)))
        end
      end

      private

      attr_reader :character, :offer_key

      def offer_label(offer)
        I18n.locale.to_s.start_with?("en") ? offer["title_en"] : offer["title_ru"]
      end

      def grant!(grant)
        grant = grant.to_h
        season_xp = grant["season_xp"].to_i
        Progress.new(character:).add_xp!(season_xp) if season_xp.positive?

        nv = grant["nv"].to_i
        if nv.positive?
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          wallet.adjust!(amount: nv, reason: "ashen.season.shop_grant", metadata: {"offer" => offer_key})
        end

        item_key = grant["item_key"].presence
        return unless item_key

        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: item_key)
        return unless template

        inventory = character.inventory || character.create_inventory!
        qty = [grant["quantity"].to_i, 1].max
        Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: qty)
      end
    end
  end
end
