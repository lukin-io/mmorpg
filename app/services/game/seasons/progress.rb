# frozen_string_literal: true

module Game
  module Seasons
    # Per-character battle-pass progress for the active Ashen season.
    # Convenience monetization: premium track unlocks with VM (time-saver rewards).
    class Progress
      Result = Struct.new(:success, :message, :xp, keyword_init: true)
      META_KEY = "ashen_season"

      def initialize(character:)
        @character = character
      end

      def snapshot
        ensure_season!
        bag = state
        season = Catalog.current
        {
          key: Catalog.current_key,
          title_ru: season["title_ru"],
          title_en: season["title_en"],
          active: Catalog.active?,
          days_left: Catalog.days_remaining,
          xp: bag["xp"].to_i,
          premium: bag["premium"] == true,
          premium_unlock_vm: season.fetch("premium_unlock_vm", 35).to_i,
          free_levels: claimable_levels("free_track", bag),
          premium_levels: claimable_levels("premium_track", bag),
          next_free: next_level_row("free_track", bag),
          next_premium: next_level_row("premium_track", bag)
        }
      end

      def add_xp!(amount)
        return Result.new(success: false, message: I18n.t("game.season.inactive")) unless Catalog.active?
        return Result.new(success: false, message: I18n.t("game.season.bad_xp")) unless amount.to_i.positive?

        character.with_lock do
          character.reload
          ensure_season!
          bag = state
          bag["xp"] = bag["xp"].to_i + amount.to_i
          write!(bag)
          Result.new(success: true, xp: bag["xp"], message: I18n.t("game.season.xp_gained", amount: amount.to_i))
        end
      end

      def unlock_premium!
        return Result.new(success: false, message: I18n.t("game.season.inactive")) unless Catalog.active?

        character.with_lock do
          character.reload
          ensure_season!
          bag = state
          return Result.new(success: true, message: I18n.t("game.season.premium_already")) if bag["premium"]

          price = Catalog.current.fetch("premium_unlock_vm", 35).to_i
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          return Result.new(success: false, message: I18n.t("game.premium_pass.short_vm", amount: price)) if wallet.veil_marks.to_i < price

          wallet.adjust_veil_marks!(
            amount: -price,
            reason: "ashen.season.premium_unlock",
            metadata: {"season" => Catalog.current_key}
          )
          bag["premium"] = true
          write!(bag)
          Result.new(success: true, message: I18n.t("game.season.premium_unlocked"))
        end
      end

      def claim!(track:, level:)
        track_key = track.to_s == "premium" ? "premium_track" : "free_track"
        claimed_key = track.to_s == "premium" ? "claimed_premium" : "claimed_free"
        level = level.to_i

        character.with_lock do
          character.reload
          ensure_season!
          return Result.new(success: false, message: I18n.t("game.season.inactive")) unless Catalog.active?

          bag = state
          if track_key == "premium_track" && bag["premium"] != true
            return Result.new(success: false, message: I18n.t("game.season.need_premium"))
          end

          row = Array(Catalog.current[track_key]).find { |r| r["level"].to_i == level }
          return Result.new(success: false, message: I18n.t("game.season.level_missing")) unless row
          return Result.new(success: false, message: I18n.t("game.season.already_claimed")) if Array(bag[claimed_key]).include?(level)
          return Result.new(success: false, message: I18n.t("game.season.need_xp")) if bag["xp"].to_i < row["xp"].to_i

          grant_reward!(row.fetch("reward", {}))
          bag[claimed_key] = Array(bag[claimed_key]) + [level]
          write!(bag)
          Result.new(success: true, message: I18n.t("game.season.claimed", level:))
        end
      end

      private

      attr_reader :character

      def ensure_season!
        bag = state
        return if bag["season_key"] == Catalog.current_key

        write!({
          "season_key" => Catalog.current_key,
          "xp" => 0,
          "premium" => false,
          "claimed_free" => [],
          "claimed_premium" => []
        })
      end

      def state
        character.metadata.to_h[META_KEY].to_h
      end

      def write!(bag)
        character.update!(metadata: character.metadata.to_h.merge(META_KEY => bag))
      end

      def claimable_levels(track_key, bag)
        claimed_key = track_key == "premium_track" ? "claimed_premium" : "claimed_free"
        claimed = Array(bag[claimed_key])
        Array(Catalog.current[track_key]).select do |row|
          bag["xp"].to_i >= row["xp"].to_i && !claimed.include?(row["level"].to_i)
        end
      end

      def next_level_row(track_key, bag)
        claimed_key = track_key == "premium_track" ? "claimed_premium" : "claimed_free"
        claimed = Array(bag[claimed_key])
        Array(Catalog.current[track_key]).find do |row|
          !claimed.include?(row["level"].to_i)
        end
      end

      def grant_reward!(reward)
        reward = reward.to_h
        nv = reward["nv"].to_i
        vm = reward["vm"].to_i
        wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
        if nv.positive?
          wallet.adjust!(amount: nv, reason: "ashen.season.reward", metadata: {"season" => Catalog.current_key})
        end
        if vm.positive?
          wallet.adjust_veil_marks!(amount: vm, reason: "ashen.season.reward", metadata: {"season" => Catalog.current_key})
        end
        item_key = reward["item_key"].presence
        return unless item_key

        Game::Professions::Templates.ensure_craft_items!
        template = ItemTemplate.find_by(key: item_key)
        return unless template

        inventory = character.inventory || character.create_inventory!
        qty = [reward["quantity"].to_i, 1].max
        Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: qty)
      end
    end
  end
end
