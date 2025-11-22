# frozen_string_literal: true

module Admin
  module Moderation
    class AppealsController < Admin::BaseController
      def update
        appeal = ::Moderation::Appeal.find(params[:id])
        authorize appeal.ticket, :update?

        workflow.resolve(
          appeal:,
          reviewer: current_user,
          status: appeal_params[:status],
          resolution_notes: appeal_params[:resolution_notes]
        )

        redirect_to admin_moderation_ticket_path(appeal.ticket), notice: "Appeal updated."
      rescue => e
        redirect_to admin_moderation_ticket_path(appeal.ticket), alert: e.message
      end

      private

      def workflow
        @workflow ||= ::Moderation::AppealWorkflow.new
      end

      def appeal_params
        params.require(:moderation_appeal).permit(:status, :resolution_notes)
      end
    end
  end
end
