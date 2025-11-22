# frozen_string_literal: true

module Moderation
  class ReportsController < ApplicationController
    def new
      authorize Moderation::Ticket
      @ticket = Moderation::Ticket.new(
        source: params[:source] || :chat,
        priority: :normal,
        origin_reference: params[:origin_reference],
        metadata: params[:metadata].is_a?(ActionController::Parameters) ? params[:metadata].to_unsafe_h : {}
      )
      @subject_user = User.find_by(id: params[:subject_user_id])
      @subject_character = Character.find_by(id: params[:subject_character_id])
    end

    def create
      authorize Moderation::Ticket
      intake = Moderation::ReportIntake.new
      ticket = intake.call(
        reporter: current_user,
        subject_user: find_user(report_params[:subject_user_id]),
        subject_character: find_character(report_params[:subject_character_id]),
        source: report_params[:source],
        category: report_params[:category],
        description: report_params[:description],
        origin_reference: report_params[:origin_reference],
        priority: report_params[:priority] || :normal,
        zone_key: report_params[:zone_key],
        evidence: report_params[:evidence],
        metadata: report_params[:metadata] || {}
      )

      redirect_to root_path, notice: "Report ##{ticket.id} submitted for review."
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      @ticket = e.record
      render :new, status: :unprocessable_entity
    end

    private

    def report_params
      params.require(:moderation_report).permit(
        :source,
        :category,
        :description,
        :subject_user_id,
        :subject_character_id,
        :origin_reference,
        :priority,
        :zone_key,
        evidence: [
          :log_excerpt,
          :screenshot_url,
          :combat_replay_id,
          :chat_log_reference,
          :additional_context
        ],
        metadata: {}
      )
    end

    def find_user(id)
      return if id.blank?

      User.find_by(id:)
    end

    def find_character(id)
      return if id.blank?

      Character.find_by(id:)
    end
  end
end
