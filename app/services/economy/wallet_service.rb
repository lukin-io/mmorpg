# frozen_string_literal: true

module Economy
  # WalletService centralizes multi-currency adjustments, transaction logging,
  # soft-cap enforcement, and sink accounting.
  #
  # Usage:
  #   Economy::WalletService.new(wallet: current_user.currency_wallet)
  #     .adjust!(currency: :gold, amount: 500, reason: "quest.reward")
  #
  #   Economy::WalletService.new(wallet: wallet)
  #     .sink!(currency: :gold, amount: 25, sink_reason: :housing_upkeep)
  class WalletService
    class InsufficientFundsError < StandardError; end

    def initialize(wallet:)
      @wallet = wallet
    end

    def adjust!(currency:, amount:, reason:, metadata: {})
      normalized_currency = normalize_currency(currency)
      amt = amount.to_i
      raise ArgumentError, "amount cannot be zero" if amt.zero?

      ApplicationRecord.transaction do
        wallet.lock!
        if amt.positive?
          apply_credit!(currency: normalized_currency, amount: amt, reason:, metadata:)
        else
          apply_debit!(currency: normalized_currency, amount: amt, reason:, metadata:)
        end
      end
      wallet
    end

    def sink!(currency:, amount:, sink_reason:, metadata: {})
      amt = amount.to_i.abs
      adjust!(
        currency: currency,
        amount: -amt,
        reason: "sink.#{sink_reason}",
        metadata: metadata
      )
      wallet.record_sink_total!(currency: currency, amount: amt)
    end

    private

    attr_reader :wallet

    def apply_credit!(currency:, amount:, reason:, metadata:)
      current_balance = wallet.balance_for(currency)
      projected_balance = current_balance + amount
      soft_cap = wallet.soft_cap_for(currency)
      overflow = [projected_balance - soft_cap, 0].max
      applied_amount = amount - overflow

      set_balance!(currency, current_balance + applied_amount)
      if applied_amount.nonzero?
        record_transaction!(
          currency: currency,
          amount: applied_amount,
          reason: reason,
          balance_after: wallet.balance_for(currency),
          metadata: metadata
        )
      end

      return if overflow.zero?

      record_transaction!(
        currency: currency,
        amount: -overflow,
        reason: "sink.soft_cap",
        balance_after: wallet.balance_for(currency),
        metadata: metadata.merge("overflow" => overflow)
      )
      wallet.record_sink_total!(currency: currency, amount: overflow)
    end

    def apply_debit!(currency:, amount:, reason:, metadata:)
      current_balance = wallet.balance_for(currency)
      projected_balance = current_balance + amount
      raise InsufficientFundsError, "insufficient #{currency}" if projected_balance.negative?

      set_balance!(currency, projected_balance)
      record_transaction!(
        currency: currency,
        amount: amount,
        reason: reason,
        balance_after: projected_balance,
        metadata: metadata
      )
    end

    def set_balance!(currency, value)
      wallet.update!("#{currency}_balance" => value)
      return unless currency == :premium_tokens

      wallet.user.update!(premium_tokens_balance: value)
    end

    def record_transaction!(currency:, amount:, reason:, balance_after:, metadata:)
      wallet.currency_transactions.create!(
        currency_type: currency,
        amount: amount,
        reason: reason,
        metadata: metadata,
        balance_after: balance_after
      )
    end

    def normalize_currency(currency)
      key = currency.to_sym
      raise ArgumentError, "Unknown currency #{currency}" unless CurrencyWallet::CURRENCIES.include?(key)

      key
    end
  end
end
