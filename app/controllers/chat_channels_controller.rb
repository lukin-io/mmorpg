# frozen_string_literal: true

class ChatChannelsController < ApplicationController
  def show
    current_user.ensure_social_features!
    @chat_channel = policy_scope(ChatChannel).find(params[:id])
    authorize @chat_channel, :show?

    prepare_local_chat_context if @chat_channel.local?
    @chat_entries = Chat::Timeline.new(
      channel: @chat_channel, viewer: current_user, session: @chat_session,
      include_game_events: @chat_channel.global? || @chat_channel.local?
    ).call
    @chat_message = ChatMessage.new

    if request.headers["Turbo-Frame"] == "chat_messages"
      render "chat_channels/compact_messages", layout: false
    end
  end

  # Current-location polling never accepts a destination channel or room key.
  # Durable personal/world events share the initial shell; ordinary rows are
  # available only within the current login and current cell/room visit.
  def local
    current_user.ensure_social_features!
    prepare_local_chat_context
    @chat_channel = ChatChannel.local.find_by("metadata ->> 'location_key' = ?", @chat_context.key) ||
      ChatChannel.new(channel_type: :local, name: "Local", metadata: {"location_key" => @chat_context.key})
    @chat_entries = Chat::Timeline.new(
      channel: @chat_channel, viewer: current_user, session: @chat_session,
      include_game_events: params[:poll] != "1"
    ).call
    @chat_message = ChatMessage.new
    render(params[:poll] == "1" ? "chat_channels/local_updates" : "chat_channels/compact_messages", layout: false)
  end

  private

  # A stale passive read must not follow its old Referer back into a gameplay
  # room. The next poll resolves the fresh audience through normal authority.
  def user_not_authorized
    return head :forbidden if action_name == "local"

    super
  end

  def game_shell_context_request?
    action_name != "local" && super
  end
end
