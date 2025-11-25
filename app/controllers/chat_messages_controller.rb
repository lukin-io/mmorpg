# frozen_string_literal: true

class ChatMessagesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_chat_channel

  def create
    authorize ChatMessage.new(chat_channel: @chat_channel), :create?

    dispatcher = Chat::MessageDispatcher.new(
      user: current_user,
      channel: @chat_channel,
      body: chat_message_params[:body]
    )

    dispatcher.call

    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to chat_channel_path(@chat_channel), notice: "Message sent." }
      format.json { head :created }
    end
  rescue Chat::Errors::MutedError,
    Chat::Errors::UnauthorizedCommandError,
    Chat::Errors::SpamThrottledError,
    Chat::Errors::PrivacyBlockedError,
    ActiveRecord::RecordInvalid => e
    handle_chat_error(e.message)
  end

  private

  def set_chat_channel
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
  end

  def chat_message_params
    params.require(:chat_message).permit(:body)
  end

  def handle_chat_error(message)
    chat_message = ChatMessage.new
    chat_message.errors.add(:base, message)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@chat_channel, :form),
          partial: "chat_messages/form",
          locals: {chat_channel: @chat_channel, chat_message:}
        ), status: :unprocessable_entity
      end
      format.html do
        flash.now[:alert] = message
        @chat_message = chat_message
        @chat_messages = @chat_channel.chat_messages.order(created_at: :desc).limit(200).reverse
        render "chat_channels/show", status: :unprocessable_entity
      end
      format.json { render json: {error: message}, status: :unprocessable_entity }
    end
  end
end
