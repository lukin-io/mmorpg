# frozen_string_literal: true

module Economy
  # Single-currency wallet for source-backed Neverlands money (`NV`).
  class WalletService
    class InsufficientFundsError < StandardError; end

    def initialize(wallet:)
      @wallet = wallet
    end

    def adjust!(amount:, reason:, metadata: {})
      amount = BigDecimal(amount.to_s)
      raise ArgumentError, "amount cannot be zero" if amount.zero?

      # A rescued ledger failure must roll its balance change back even when
      # the caller continues an enclosing gameplay transaction.
      ApplicationRecord.transaction(requires_new: true) do
        wallet.lock!
        projected_balance = wallet.nv_balance + amount
        raise InsufficientFundsError, "insufficient NV" if projected_balance.negative?

        wallet.update!(nv_balance: projected_balance)
        wallet.currency_transactions.create!(
          amount: amount,
          reason: reason,
          metadata: metadata,
          balance_after: projected_balance
        )
      end

      wallet
    end

    private

    attr_reader :wallet
  end
end
