# frozen_string_literal: true

class ChatMessagesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_chat_channel

  def create
    authorize ChatMessage.new(chat_channel: @chat_channel), :create?

    dispatcher = Chat::MessageDispatcher.new(
      user: current_user,
      channel: @chat_channel,
      body: chat_message_params[:body],
      context_key: params[:context_key],
      session: current_user_session
    )

    result = dispatcher.call

    respond_to do |format|
      format.turbo_stream do
        if @chat_channel.local?
          render turbo_stream: turbo_stream.append(
            Chat::TimelineBroadcaster::TARGET_DOM_ID,
            partial: "chat_messages/chat_message",
            locals: {chat_message: result.message}
          )
        else
          head :ok
        end
      end
      format.html { redirect_to chat_channel_path(@chat_channel), notice: "Message sent." }
      format.json { head :created }
    end
  rescue Chat::Errors::MutedError,
    Chat::Errors::PrivacyBlockedError,
    ActiveRecord::RecordInvalid,
    ArgumentError => e
    handle_chat_error(e.message)
  end

  private

  def set_chat_channel
    @chat_channel = if params[:chat_channel_id].present?
      ChatChannel.find(params[:chat_channel_id])
    else
      current_user.ensure_social_features!
      prepare_local_chat_context
      unless params[:context_key].present?
        raise Pundit::NotAuthorizedError, "Current chat location required"
      end
      Chat::ChannelRouter.new(user: current_user).resolve(scope: :local)
    end
  end

  def chat_message_params
    params.require(:chat_message).permit(:body)
  end

  def handle_chat_error(message)
    chat_message = ChatMessage.new
    chat_message.errors.add(:base, message)

    respond_to do |format|
      format.turbo_stream do
        stream = if @chat_channel.local?
          turbo_stream.update("flash", partial: "shared/flash", locals: {type: "alert", message:})
        else
          turbo_stream.replace(
            dom_id(@chat_channel, :form),
            partial: "chat_messages/form",
            locals: {chat_channel: @chat_channel, chat_message:}
          )
        end
        render turbo_stream: stream, status: :unprocessable_entity
      end
      format.html do
        flash.now[:alert] = message
        @chat_message = chat_message
        prepare_local_chat_context if @chat_channel.local?
        @chat_entries = Chat::Timeline.new(
          channel: @chat_channel, viewer: current_user, session: current_user_session,
          include_game_events: @chat_channel.global? || @chat_channel.local?
        ).call
        render "chat_channels/show", status: :unprocessable_entity
      end
      format.json { render json: {error: message}, status: :unprocessable_entity }
    end
  end
end
