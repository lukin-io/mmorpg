# frozen_string_literal: true

module Admin
  module Moderation
    class TicketsController < Admin::BaseController
      def index
        authorize ::Moderation::Ticket
        scoped = policy_scope(::Moderation::Ticket)
        @tickets = scoped.open_queue.includes(:reporter, :subject_user).recent
        @dashboard = ::Moderation::DashboardPresenter.new(scope: scoped)
      end

      def show
        @ticket = find_ticket
        authorize @ticket
        @action = ::Moderation::Action.new
        @appeal = ::Moderation::Appeal.new(ticket: @ticket)
      end

      def update
        ticket = find_ticket
        authorize ticket

        if ticket.update(ticket_params)
          redirect_to admin_moderation_ticket_path(ticket), notice: "Ticket updated."
        else
          redirect_to admin_moderation_ticket_path(ticket), alert: ticket.errors.full_messages.to_sentence
        end
      end

      private

      def find_ticket
        policy_scope(::Moderation::Ticket).find(params[:id])
      end

      def ticket_params
        params.require(:moderation_ticket).permit(:priority, :status, :assigned_moderator_id)
      end
    end
  end
end
