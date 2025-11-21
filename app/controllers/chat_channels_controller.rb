# frozen_string_literal: true

class ChatChannelsController < ApplicationController
  def index
    current_user.ensure_social_features!
    @chat_channels = policy_scope(ChatChannel).order(:name)
  end

  def show
    current_user.ensure_social_features!
    @chat_channel = policy_scope(ChatChannel).find(params[:id])
    authorize @chat_channel, :show?

    @chat_messages = @chat_channel.chat_messages.order(created_at: :desc).limit(200).reverse
    @chat_message = ChatMessage.new
  end
end
