# frozen_string_literal: true

class ChatChannelsController < ApplicationController
  def show
    current_user.ensure_social_features!
    @chat_channel = policy_scope(ChatChannel).find(params[:id])
    authorize @chat_channel, :show?

    messages = @chat_channel.chat_messages.order(created_at: :desc).limit(200).reverse
    @chat_messages = Chat::IgnoreFilter.filter_for_user(messages, current_user)
    @chat_message = ChatMessage.new
  end
end
