# frozen_string_literal: true

module Admin
  module Moderation
    class ActionsController < Admin::BaseController
      def create
        ticket = policy_scope(::Moderation::Ticket).find(params[:ticket_id])
        authorize ticket, :update?

        service = ::Moderation::PenaltyService.new(ticket:, actor: current_user)
        service.call(
          action_type: action_params[:action_type],
          reason: action_params[:reason],
          duration_seconds: action_params[:duration_seconds],
          metadata: action_params[:metadata] || {}
        )

        redirect_to admin_moderation_ticket_path(ticket), notice: "Action recorded."
      rescue => e
        redirect_to admin_moderation_ticket_path(ticket), alert: e.message
      end

      private

      def action_params
        params.require(:moderation_action).permit(:action_type, :reason, :duration_seconds, metadata: {})
      end
    end
  end
end
