# frozen_string_literal: true

class ChatReportsController < ApplicationController
  def index
    authorize ChatReport
    @chat_reports = policy_scope(ChatReport).includes(:chat_message, :reporter).order(created_at: :desc)
  end

  def create
    current_user.ensure_social_features!
    authorize ChatReport

    ActiveRecord::Base.transaction do
      @chat_report = current_user.chat_reports.create!(processed_params)
      Moderation::ReportIntake.new.call(
        reporter: current_user,
        subject_user: @chat_report.chat_message&.sender,
        source: :chat,
        category: :chat_abuse,
        description: @chat_report.reason,
        evidence: @chat_report.evidence,
        metadata: {
          chat_report_id: @chat_report.id,
          chat_message_id: @chat_report.chat_message_id
        },
        chat_report: @chat_report
      )
    end

    redirect_back fallback_location: chat_channels_path, notice: "Report submitted for moderator review."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: chat_channels_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def processed_params
    permitted = chat_report_params.to_h
    evidence = permitted.delete("evidence") || {}
    evidence = evidence.present? ? evidence : {}

    if permitted["chat_message_id"].present?
      message = ChatMessage.find_by(id: permitted["chat_message_id"])
      evidence = evidence.merge(
        "message_preview" => message&.filtered_body,
        "message_id" => message&.id
      ).compact
    end

    permitted.merge(evidence:)
  end

  def chat_report_params
    params.require(:chat_report).permit(:chat_message_id, :reason, evidence: {})
  end
end
