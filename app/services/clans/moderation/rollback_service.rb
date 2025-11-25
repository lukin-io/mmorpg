# frozen_string_literal: true

module Clans
  module Moderation
    # RollbackService lets GMs undo abusive actions (treasury withdrawals, etc.)
    # or dissolve inactive clans.
    #
    # Usage:
    #   service = Clans::Moderation::RollbackService.new(clan: clan, gm_user: current_user)
    #   service.rollback!(log_entry_id: params[:log_entry_id])
    #   service.dissolve!(reason: "Inactive > 90 days")
    class RollbackService
      def initialize(clan:, gm_user:)
        @clan = clan
        @gm_user = gm_user
      end

      def rollback!(log_entry_id:)
        log_entry = clan.clan_log_entries.find(log_entry_id)
        case log_entry.action
        when "treasury.withdraw"
          reverse_treasury!(log_entry)
        else
          raise ArgumentError, "Unsupported rollback for #{log_entry.action}"
        end
      end

      def dissolve!(reason:)
        ClanModerationAction.create!(
          clan: clan,
          gm_user: gm_user,
          action_type: "dissolve",
          notes: reason
        )

        Clan.transaction do
          clan.clan_memberships.destroy_all
          clan.clan_territories.destroy_all
          clan.destroy!
        end
      end

      private

      attr_reader :clan, :gm_user

      def reverse_treasury!(log_entry)
        transaction_id = log_entry.metadata["transaction_id"]
        original = clan.clan_treasury_transactions.find_by(id: transaction_id)
        return unless original

        service = Clans::TreasuryService.new(clan: clan, actor: gm_user, membership: nil)
        service.deposit!(
          currency: original.currency_type,
          amount: original.amount.abs,
          reason: "moderation.rollback",
          metadata: {original_transaction_id: original.id}
        )

        ClanModerationAction.create!(
          clan: clan,
          gm_user: gm_user,
          target: original,
          action_type: "rollback",
          notes: "Reversed treasury transaction #{original.id}"
        )
      end
    end
  end
end
