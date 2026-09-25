# frozen_string_literal: true

module Game
  module World
    # Simple Ashen bank vault for NV stored on character.metadata.
    class BankVault
      Result = Struct.new(:success, :message, :balance, keyword_init: true)
      META_KEY = "ashen_bank_nv"

      def initialize(character:, amount:, action:)
        @character = character
        @amount = amount.to_i
        @action = action.to_s
      end

      def self.balance_for(character)
        character.metadata.to_h[META_KEY].to_i
      end

      def call
        return failure(I18n.t("game.buildings.bank_bad_amount")) if amount <= 0
        return failure(I18n.t("game.buildings.bank_bad_action")) unless %w[deposit withdraw].include?(action)

        character.with_lock do
          character.reload
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          vault = self.class.balance_for(character)

          if action == "deposit"
            if wallet.nv_balance.to_i < amount
              return failure(I18n.t("game.buildings.bank_short_wallet", amount:))
            end
            wallet.adjust!(amount: -amount, reason: "ashen.bank_deposit", metadata: {"amount" => amount})
            next_balance = vault + amount
          else
            if vault < amount
              return failure(I18n.t("game.buildings.bank_short_vault", amount:))
            end
            wallet.adjust!(amount: amount, reason: "ashen.bank_withdraw", metadata: {"amount" => amount})
            next_balance = vault - amount
          end

          character.update!(metadata: character.metadata.to_h.merge(META_KEY => next_balance))
          Result.new(
            success: true,
            balance: next_balance,
            message: I18n.t(
              action == "deposit" ? "game.buildings.bank_deposited" : "game.buildings.bank_withdrawn",
              amount:,
              balance: next_balance
            )
          )
        end
      end

      private

      attr_reader :character, :amount, :action

      def failure(message)
        Result.new(success: false, message:, balance: self.class.balance_for(character))
      end
    end
  end
end
