# frozen_string_literal: true

module Payments
  class PremiumTokenLedger
    class InsufficientBalanceError < StandardError; end

    def self.credit(user:, amount:, reason:, reference: nil, metadata: {}, actor: nil)
      new(
        user: user,
        amount: amount,
        entry_type: :purchase,
        reason: reason,
        reference: reference,
        metadata: metadata,
        actor: actor || user
      ).apply!
    end

    def self.debit(user:, amount:, reason:, reference: nil, metadata: {}, actor:)
      new(
        user: user,
        amount: -amount.abs,
        entry_type: :spend,
        reason: reason,
        reference: reference,
        metadata: metadata,
        actor: actor
      ).apply!
    end

    def self.adjust(user:, delta:, reason:, reference: nil, metadata: {}, actor:)
      new(
        user: user,
        amount: delta,
        entry_type: :adjustment,
        reason: reason,
        reference: reference,
        metadata: metadata,
        actor: actor
      ).apply!
    end

    def initialize(user:, amount:, entry_type:, reason:, reference:, metadata:, actor:)
      @user = user
      @amount = amount.to_i
      @entry_type = entry_type
      @reason = reason
      @reference = reference
      @metadata = metadata || {}
      @actor = actor
    end

    def apply!
      ApplicationRecord.transaction do
        user.lock!

        new_balance = user.premium_tokens_balance + amount
        raise InsufficientBalanceError, "Cannot spend more tokens than available" if new_balance.negative?

        user.update!(premium_tokens_balance: new_balance)

        entry = user.premium_token_ledger_entries.create!(
          entry_type: entry_type,
          delta: amount,
          balance_after: new_balance,
          reference: reference,
          reason: reason,
          metadata: metadata
        )

        AuditLogger.log(
          actor: actor || user,
          action: "premium_tokens.#{entry_type}",
          target: reference || user,
          metadata: metadata.merge(
            user_id: user.id,
            delta: amount,
            balance_after: new_balance,
            reason: reason
          )
        )

        entry
      end
    end

    private

    attr_reader :user, :amount, :entry_type, :reason, :reference, :metadata, :actor
  end
end
