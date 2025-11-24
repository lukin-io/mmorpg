# frozen_string_literal: true

module Trades
  # Orchestrates the lifecycle of a trade session, ensuring both parties confirm.
  #
  # Usage:
  #   Trades::SessionManager.new(initiator: user, recipient: other_user).start!
  #
  # Methods:
  #   - start!  -> creates a TradeSession
  #   - confirm!(session:, actor:) -> advances to confirming/completed states
  class SessionManager
    SESSION_TTL = 15.minutes

    def initialize(initiator:, recipient:)
      @initiator = initiator
      @recipient = recipient
    end

    def start!
      TradeSession.create!(
        initiator:,
        recipient:,
        status: :pending,
        expires_at: Time.current + SESSION_TTL
      )
    end

    def confirm!(session:, actor:)
      raise Pundit::NotAuthorizedError unless [session.initiator, session.recipient].include?(actor)

      completed = false
      session.with_lock do
        new_status = session.confirming? ? :completed : :confirming
        completed = new_status == :completed
        session.update!(
          status: new_status,
          completed_at: completed ? Time.current : session.completed_at
        )
      end

      Trades::SettlementService.new(trade_session: session).call if completed
      session
    end

    private

    attr_reader :initiator, :recipient
  end
end
