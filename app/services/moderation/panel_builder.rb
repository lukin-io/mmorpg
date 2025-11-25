# frozen_string_literal: true

module Moderation
  # PanelBuilder composes policy summaries, penalties, and appeal statuses for the player-facing moderation panel.
  #
  # Usage:
  #   Moderation::PanelBuilder.new(user: current_user).call
  #
  # Returns:
  #   Hash with :tickets, :penalties, and :policy_keys.
  class PanelBuilder
    def initialize(user:)
      @user = user
    end

    def call
      tickets = user.moderation_actions_received.includes(:ticket)
      {
        tickets: format_tickets(tickets),
        penalties: penalty_state,
        policy_keys: tickets.filter_map { |action| action.ticket&.policy_key }.compact.uniq
      }
    end

    private

    attr_reader :user

    def format_tickets(actions)
      actions.map do |action|
        ticket = action.ticket
        {
          ticket_id: ticket&.id,
          status: ticket&.status,
          penalty_state: ticket&.penalty_state,
          appeal_status: ticket&.appeal_status,
          policy_summary: ticket&.policy_summary
        }
      end
    end

    def penalty_state
      {
        trade_locked_until: user.trade_locked_until,
        suspended_until: user.suspended_until
      }
    end
  end
end
