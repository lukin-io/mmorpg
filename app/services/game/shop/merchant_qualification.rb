# frozen_string_literal: true

module Game
  module Shop
    # The captured Forpost Merchant qualification: accept at Market, pay for a
    # receipt at Shop, then return to Market. Character metadata retains the
    # step and receipt ledger identity; the paid state prevents repeat charges.
    # Inputs: current character, allowlisted action, optional server clock.
    # Output: Result. Payment, Shop funds, audit and progress commit together.
    # Completing these steps grants license eligibility, not an invented item.
    class MerchantQualification
      Result = Struct.new(:success, :message, keyword_init: true)
      class Unavailable < StandardError; end

      COST = BigDecimal("1000")
      STATE_KEY = "merchant_qualification"
      ACTION_LOCATIONS = {"accept" => :market, "pay" => :shop, "complete" => :market}.freeze
      NODE_KEYS = {market: "forpost1", shop: "main"}.freeze
      PAYMENT_REASON = "shop.merchant_qualification"

      def initialize(character:, clock: -> { Time.current })
        @character = character
        @clock = clock
      end

      def call(action:)
        location = ACTION_LOCATIONS[action.to_s]
        reject!(I18n.t("game.shop.merchant_unknown_step")) unless location

        ApplicationRecord.transaction(requires_new: true) do
          character.lock!
          validate_character!
          account = validate_location!(location)
          reject!(I18n.t("game.shop.merchant_progress_unavailable")) if status == "invalid"
          case action.to_s
          when "accept" then accept
          when "pay" then pay(account)
          when "complete" then complete
          end
        end
      rescue Unavailable, TradeOffers::Unavailable => error
        Result.new(success: false, message: error.message)
      rescue Economy::WalletService::InsufficientFundsError
        Result.new(success: false, message: I18n.t("game.shop.merchant_receipt_cost"))
      end

      # Read-only display eligibility; request actions revalidate the building,
      # persisted room and busy state under the character lock.
      def visible_at?(location)
        character.owns_perk?(:merchant) && at_node?(location)
      end

      def status
        unlocks = character.metadata.to_h["profession_unlocks"]
        return "completed" if unlocks.is_a?(Hash) && unlocks["merchant"] == true
        return "not_started" unless character.metadata.to_h.key?(STATE_KEY)
        return "invalid" unless progress.is_a?(Hash) && progress["accepted_at"].is_a?(String)
        return "invalid" unless %w[accepted paid completed].include?(progress["status"])
        if %w[paid completed].include?(progress["status"])
          return "invalid" unless progress["receipt_transaction_id"].is_a?(Integer) && progress["paid_at"].is_a?(String)
        end

        progress.fetch("status")
      end

      private

      attr_reader :character, :clock

      def progress
        character.metadata.to_h[STATE_KEY]
      end

      def at_node?(location)
        position = character.position
        zone = position&.zone
        key = NODE_KEYS[location]
        return false unless key && position&.active? && zone&.city?

        zone.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY && zone.city_node_key == key &&
          zone.name == Game::World::CityCatalog.node(key).fetch("zone_name")
      end

      def validate_character!
        reject!(I18n.t("game.shop.merchant_perk_required")) unless character.owns_perk?(:merchant)
        character.position&.reload
        busy = character.active_airship_journey || MovementCommand.moving.where(character:).exists? ||
          Game::World::LocalActionState.new(character:).call ||
          character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
        reject!(I18n.t("game.shop.merchant_finish_action")) if busy
      end

      def validate_location!(location)
        place = I18n.t("game.shop.forpost_#{location}")
        reject!(I18n.t("game.shop.merchant_enter_location", place:)) unless at_node?(location)
        if location == :shop
          shop = Location.new(character:).call
          unless shop.account && shop.building.is_a?(CityHotspot) && shop.building.key == "shop"
            reject!(I18n.t("game.shop.shop_not_trading"))
          end
          return shop.account
        end

        context = character.gameplay_context
        unless context["name"] == "city_building" && context.dig("params", "building_key") == "market" &&
            Game::World::CityBuildingCatalog.accessible?(character:, building_key: "market")
          reject!(I18n.t("game.shop.merchant_enter_market"))
        end
        nil
      end

      def accept
        return completed_result if status == "completed"
        return Result.new(success: true, message: I18n.t("game.shop.merchant_receipt_received")) if status == "paid"
        if status == "not_started"
          save_progress!("status" => "accepted", "accepted_at" => clock.call.iso8601(6))
        end
        Result.new(success: true, message: I18n.t("game.shop.merchant_accepted"))
      end

      def pay(account)
        return completed_result if status == "completed"
        return Result.new(success: true, message: I18n.t("game.shop.merchant_receipt_received")) if status == "paid"
        reject!(I18n.t("game.shop.merchant_accept_first")) unless status == "accepted"

        account.lock!
        wallet = character.user.currency_wallet
        reject!(I18n.t("game.shop.merchant_wallet_unavailable")) unless wallet
        wallet.lock!
        reject!(I18n.t("game.shop.shop_payment_blocked")) if account.nv_balance + COST >= ShopAccount::NV_LIMIT
        wallet.adjust!(amount: -COST, reason: PAYMENT_REASON,
          metadata: {"character_id" => character.id, "shop_account_id" => account.id, "qualification" => "merchant"})
        receipt = wallet.currency_transactions.order(:id).last!
        account.update!(nv_balance: account.nv_balance + COST)
        save_progress!(progress.merge("status" => "paid", "paid_at" => clock.call.iso8601(6),
          "receipt_transaction_id" => receipt.id))
        Result.new(success: true, message: I18n.t("game.shop.merchant_receipt_received"))
      end

      def complete
        return completed_result if status == "completed"
        reject!(I18n.t("game.shop.merchant_collect_receipt_first")) unless status == "paid"
        receipt = character.user.currency_wallet&.currency_transactions&.find_by(
          id: progress.fetch("receipt_transaction_id"), reason: PAYMENT_REASON, amount: -COST
        )
        unless receipt && receipt.metadata.to_h["character_id"] == character.id
          reject!(I18n.t("game.shop.merchant_receipt_unavailable"))
        end

        unlocks = character.metadata.to_h["profession_unlocks"]
        unlocks = {} unless unlocks.is_a?(Hash)
        character.update!(metadata: character.metadata.to_h.merge(
          "profession_unlocks" => unlocks.merge("merchant" => true),
          STATE_KEY => progress.merge("status" => "completed", "completed_at" => clock.call.iso8601(6))
        ))
        completed_result
      end

      def completed_result
        Result.new(success: true, message: I18n.t("game.shop.merchant_completed"))
      end

      def save_progress!(value)
        character.update!(metadata: character.metadata.to_h.merge(STATE_KEY => value))
      end

      def reject!(message)
        raise Unavailable, message
      end
    end
  end
end
