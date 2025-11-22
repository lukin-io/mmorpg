# frozen_string_literal: true

module Moderation
  class AppealsController < ApplicationController
    def new
      @ticket = find_ticket
      authorize @ticket, :appeal?
      @appeal = ::Moderation::Appeal.new(ticket: @ticket)
    end

    def create
      ticket = find_ticket
      authorize ticket, :appeal?

      workflow = ::Moderation::AppealWorkflow.new
      workflow.submit(ticket:, appellant: current_user, body: appeal_params[:body])

      redirect_to mail_messages_path, notice: "Appeal submitted."
    rescue => e
      flash.now[:alert] = e.message
      @ticket = ticket
      @appeal = ::Moderation::Appeal.new(ticket:, body: appeal_params[:body])
      render :new, status: :unprocessable_entity
    end

    private

    def find_ticket
      ::Moderation::Ticket.find(params[:ticket_id])
    end

    def appeal_params
      params.require(:moderation_appeal).permit(:body)
    end
  end
end
