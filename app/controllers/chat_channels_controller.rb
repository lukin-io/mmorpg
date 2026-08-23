# frozen_string_literal: true

class ChatChannelsController < ApplicationController
  def show
    current_user.ensure_social_features!
    @chat_channel = policy_scope(ChatChannel).find(params[:id])
    authorize @chat_channel, :show?

    @chat_entries = Chat::Timeline.new(channel: @chat_channel, viewer: current_user).call
    @chat_message = ChatMessage.new

    if request.headers["Turbo-Frame"] == "chat_messages"
      render "chat_channels/compact_messages", layout: false
    end
  end
end
