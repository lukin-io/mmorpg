# frozen_string_literal: true

module Trades
  # SettlementService moves currencies between wallets when both players confirm a trade.
  class SettlementService
    def initialize(trade_session:, wallet_service: Economy::WalletService, premium_ledger: Payments::PremiumTokenLedger)
      @trade_session = trade_session
      @wallet_service = wallet_service
      @premium_ledger = premium_ledger
    end

    def call
      ApplicationRecord.transaction do
        settle_currency_items!
        mark_session_completed!
      end
    end

    private

    attr_reader :trade_session, :wallet_service, :premium_ledger

    def settle_currency_items!
      trade_session.trade_items.select(&:currency?).each do |item|
        sender = item.owner
        receiver = counterparty_for(sender)
        next unless receiver

        if item.currency_type == "premium_tokens"
          transfer_premium_tokens(item:, sender:, receiver:)
        else
          transfer_wallet_currency(item:, sender:, receiver:)
        end
      end
    end

    def transfer_wallet_currency(item:, sender:, receiver:)
      wallet_service.new(wallet: sender.currency_wallet).adjust!(
        currency: item.currency_type.to_sym,
        amount: -item.currency_amount,
        reason: "trade.transfer",
        metadata: metadata_for(item:, sender:, receiver:)
      )
      wallet_service.new(wallet: receiver.currency_wallet).adjust!(
        currency: item.currency_type.to_sym,
        amount: item.currency_amount,
        reason: "trade.transfer",
        metadata: metadata_for(item:, sender:, receiver:)
      )
    rescue Economy::WalletService::InsufficientFundsError => e
      raise Pundit::NotAuthorizedError, e.message
    end

    def transfer_premium_tokens(item:, sender:, receiver:)
      premium_ledger.debit(
        user: sender,
        amount: item.currency_amount,
        reason: "trade.transfer",
        actor: sender,
        metadata: metadata_for(item:, sender:, receiver:)
      )
      premium_ledger.credit(
        user: receiver,
        amount: item.currency_amount,
        reason: "trade.transfer",
        reference: trade_session,
        metadata: metadata_for(item:, sender:, receiver:),
        actor: receiver
      )
    end

    def metadata_for(item:, sender:, receiver:)
      {
        trade_session_id: trade_session.id,
        sender_id: sender.id,
        receiver_id: receiver.id,
        currency: item.currency_type
      }
    end

    def counterparty_for(user)
      if trade_session.initiator == user
        trade_session.recipient
      elsif trade_session.recipient == user
        trade_session.initiator
      end
    end

    def mark_session_completed!
      trade_session.update!(completed_at: Time.current) unless trade_session.completed_at?
    end
  end
end
