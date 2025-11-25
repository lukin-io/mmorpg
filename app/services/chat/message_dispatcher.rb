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

    def initialize(user:, channel:, body:, moderation_handler: Chat::Moderation::CommandHandler.new, spam_throttler: nil)
      @user = user
      @channel = channel
      @body = body.to_s.strip
      @moderation_handler = moderation_handler
      @spam_throttler = spam_throttler
    end

    def call
      raise ArgumentError, "message cannot be blank" if body.blank?

      pipeline_result = ::Moderation::ChatPipeline.new(
        user:,
        channel:,
        input: body,
        moderation_handler: moderation_handler,
        spam_throttler: spam_throttler
      ).call

      if pipeline_result.command_executed?
        message = create_system_message(pipeline_result.system_message)
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

    def spam_throttler
      @spam_throttler ||= Chat::SpamThrottler.new(user:, channel:)
    end
  end
end
