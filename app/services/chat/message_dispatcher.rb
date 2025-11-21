# frozen_string_literal: true

module Chat
  # Coordinates validations and side-effects when a user posts a chat message.
  #
  # Usage:
  #   Chat::MessageDispatcher.new(user: current_user, channel: channel, body: params[:body]).call
  #
  # Returns:
  #   Chat::MessageDispatcher::Result with:
  #     - message: ChatMessage that was persisted (may be a system entry if a GM command was run)
  #     - command_executed?: Boolean indicating if a GM command handled the input
  class MessageDispatcher
    Result = Struct.new(:message, :command_executed?, keyword_init: true)

    def initialize(user:, channel:, body:, moderation_handler: Chat::Moderation::CommandHandler.new)
      @user = user
      @channel = channel
      @body = body.to_s.strip
      @moderation_handler = moderation_handler
    end

    def call
      raise ArgumentError, "message cannot be blank" if body.blank?

      ensure_player_can_post!

      command_result = moderation_handler.call(user:, channel:, input: body)
      if command_result&.handled?
        message = create_system_message(command_result.system_message)
        return Result.new(message:, command_executed?: true)
      end

      channel.ensure_membership!(user)

      message = channel.chat_messages.create!(
        sender: user,
        body: body,
        visibility: :normal,
        metadata: default_metadata
      )

      Result.new(message:, command_executed?: false)
    end

    private

    attr_reader :user, :channel, :body, :moderation_handler

    def ensure_player_can_post!
      user.ensure_social_features!

      raise Chat::Errors::MutedError, "You are muted globally" if ChatModerationAction.muting?(user:, channel:)

      membership = channel.memberships.find_by(user:)
      raise Chat::Errors::MutedError, "Muted in this channel" if membership&.muted?
    end

    def create_system_message(text)
      channel.chat_messages.create!(
        sender: user,
        body: text,
        filtered_body: text,
        visibility: :system,
        metadata: default_metadata.merge("system" => true)
      )
    end

    def default_metadata
      {
        "sender_role" => user.roles.pluck(:name),
        "channel_type" => channel.channel_type
      }
    end
  end
end
