# frozen_string_literal: true

class ChatReportsController < ApplicationController
  def index
    authorize ChatReport
    @chat_reports = policy_scope(ChatReport).includes(:chat_message, :reporter).order(created_at: :desc)
  end

  def create
    current_user.ensure_social_features!
    @chat_report = current_user.chat_reports.new(processed_params)
    authorize @chat_report

    if @chat_report.save
      redirect_back fallback_location: chat_channels_path, notice: "Report submitted for moderator review."
    else
      redirect_back fallback_location: chat_channels_path, alert: @chat_report.errors.full_messages.to_sentence
    end
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
