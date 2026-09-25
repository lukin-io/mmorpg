# frozen_string_literal: true

module Economy
  # Wallet ledger for source-backed Neverlands money (`NV`) plus Ashen premium
  # Veil Marks (`VM`) used for combat trauma/heal scrolls.
  class WalletService
    class InsufficientFundsError < StandardError; end

    def initialize(wallet:)
      @wallet = wallet
    end

    def adjust!(amount:, reason:, metadata: {})
      amount = BigDecimal(amount.to_s)
      raise ArgumentError, I18n.t("errors.amount_cannot_be_zero") if amount.zero?

      # A rescued ledger failure must roll its balance change back even when
      # the caller continues an enclosing gameplay transaction.
      ApplicationRecord.transaction(requires_new: true) do
        wallet.lock!
        projected_balance = wallet.nv_balance + amount
        raise InsufficientFundsError, I18n.t("game.shop.not_enough_nv") if projected_balance.negative?

        wallet.update!(nv_balance: projected_balance)
        wallet.currency_transactions.create!(
          amount: amount,
          reason: reason,
          metadata: metadata.to_h.merge("currency" => "nv"),
          balance_after: projected_balance
        )
      end

      wallet
    end

    def adjust_veil_marks!(amount:, reason:, metadata: {})
      amount = BigDecimal(amount.to_s)
      raise ArgumentError, I18n.t("errors.amount_cannot_be_zero") if amount.zero?

      ApplicationRecord.transaction(requires_new: true) do
        wallet.lock!
        projected = wallet.veil_marks.to_d + amount
        raise InsufficientFundsError, I18n.t("errors.insufficient_veil_marks") if projected.negative?

        wallet.update!(veil_marks: projected)
        wallet.currency_transactions.create!(
          amount: amount,
          reason: reason,
          metadata: metadata.to_h.merge("currency" => "veil_marks"),
          balance_after: projected
        )
      end

      wallet
    end

    private

    attr_reader :wallet
  end
end
