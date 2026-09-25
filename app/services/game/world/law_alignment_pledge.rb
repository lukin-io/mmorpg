# frozen_string_literal: true

module Game
  module World
    # Ashen Law Abode: declare or change character alignment (source-backed axes).
    class LawAlignmentPledge
      Result = Struct.new(:success, :message, keyword_init: true)
      CHANGE_COST = 25
      CHOICES = %w[law light balance chaos dark].freeze

      def initialize(character:, alignment:)
        @character = character
        @alignment = alignment.to_s
      end

      def call
        unless CHOICES.include?(alignment)
          return Result.new(success: false, message: I18n.t("game.buildings.law_bad_alignment"))
        end

        character.with_lock do
          character.reload
          if character.in_combat?
            return Result.new(success: false, message: I18n.t("game.buildings.law_in_combat"))
          end
          if character.alignment == alignment
            return Result.new(success: false, message: I18n.t("game.buildings.law_already"))
          end

          first_pledge = character.alignment.to_s == Character::ALIGNMENTS[:none]
          unless first_pledge
            wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
            if wallet.nv_balance.to_i < CHANGE_COST
              return Result.new(success: false, message: I18n.t("game.buildings.law_short", amount: CHANGE_COST))
            end
            wallet.adjust!(
              amount: -CHANGE_COST,
              reason: "ashen.law_alignment_change",
              metadata: {"from" => character.alignment, "to" => alignment}
            )
          end

          character.update!(alignment:)
          label = I18n.t("game.buildings.law_alignment.#{alignment}")
          if first_pledge
            Result.new(success: true, message: I18n.t("game.buildings.law_pledged", name: label))
          else
            Result.new(
              success: true,
              message: I18n.t("game.buildings.law_changed", name: label, amount: CHANGE_COST)
            )
          end
        end
      end

      private

      attr_reader :character, :alignment
    end
  end
end
