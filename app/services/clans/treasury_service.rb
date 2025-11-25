# frozen_string_literal: true

module Clans
  # TreasuryService centralizes deposits/withdrawals against a clan treasury and
  # enforces per-role withdrawal limits defined in config/gameplay/clans.yml.
  #
  # Usage:
  #   service = Clans::TreasuryService.new(clan:, actor:, membership:)
  #   service.deposit!(currency: :gold, amount: 5000, reason: "clan_quest_reward")
  #   service.withdraw!(currency: :gold, amount: 1000, reason: "repair_costs")
  class TreasuryService
    class PermissionError < StandardError; end
    class LimitExceeded < StandardError; end
    class InsufficientFunds < StandardError; end

    def initialize(clan:, actor:, membership:, logger: Clans::LogWriter)
      @clan = clan
      @actor = actor
      @membership = membership
      @logger = logger
    end

    def deposit!(currency:, amount:, reason:, metadata: {})
      raise ArgumentError, "Amount must be positive" unless amount.positive?

      record_transaction!(
        currency: currency,
        amount: amount,
        reason: reason,
        metadata: metadata.merge(direction: "deposit")
      )
    end

    def withdraw!(currency:, amount:, reason:, metadata: {})
      raise ArgumentError, "Amount must be positive" unless amount.positive?

      ensure_withdraw_permission!(currency, amount)
      ensure_balance!(currency, amount)

      record_transaction!(
        currency: currency,
        amount: -amount,
        reason: reason,
        metadata: metadata.merge(direction: "withdraw")
      )
    end

    private

    attr_reader :clan, :actor, :membership, :logger

    def ensure_withdraw_permission?(permission_key)
      actor&.has_any_role?(:gm, :admin) ||
        membership&.permission_matrix&.allows?(permission_key)
    end

    def ensure_withdraw_permission!(currency, amount)
      unless ensure_withdraw_permission?(:manage_treasury)
        raise PermissionError, "You do not have access to the clan treasury."
      end

      return if actor&.has_any_role?(:gm, :admin)

      limit = clan.withdrawal_limit_for(membership.role, currency)
      raise LimitExceeded, "Withdrawal exceeds your #{currency} limit." if amount > limit
    end

    def ensure_balance!(currency, amount)
      return if clan.treasury_balance(currency) >= amount

      raise InsufficientFunds, "The clan treasury does not have enough #{currency}."
    end

    def record_transaction!(currency:, amount:, reason:, metadata:)
      clan.with_lock do
        clan.update_treasury!(currency, amount)
        transaction = clan.clan_treasury_transactions.create!(
          clan: clan,
          actor: actor,
          currency_type: currency,
          amount: amount,
          reason: reason,
          metadata: metadata
        )

        logger.new(clan:).record!(
          action: "treasury.#{metadata[:direction]}",
          actor: actor,
          metadata: metadata.merge(
            transaction_id: transaction.id,
            currency: currency,
            amount: amount,
            reason: reason
          )
        )

        transaction
      end
    end
  end
end
