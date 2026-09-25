# frozen_string_literal: true

module Game
  module World
    # Temple rite: pay a small NV fee to clear light injuries only.
    class TempleBlessing
      Result = Struct.new(:success, :message, keyword_init: true)
      COST_NV = 5

      def initialize(character:)
        @character = character
      end

      def call
        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.temple_in_combat"))
          end

          injuries = Game::Combat::InjuryState.new(character:)
          light = injuries.active.count { |row| row["severity"].to_s == "light" }
          unless light.positive?
            return Result.new(success: false, message: I18n.t("game.buildings.temple_no_light"))
          end

          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          if wallet.nv_balance.to_i < COST_NV
            return Result.new(success: false, message: I18n.t("game.buildings.temple_short", amount: COST_NV))
          end

          wallet.adjust!(
            amount: -COST_NV,
            reason: "ashen.temple_blessing",
            metadata: {"building" => "temple"}
          )
          removed = injuries.clear_light!
          Result.new(
            success: true,
            message: I18n.t("game.buildings.temple_blessed", count: removed, amount: COST_NV)
          )
        end
      end

      private

      attr_reader :character
    end
  end
end
