# frozen_string_literal: true

module Chat
  # Coordinates validations and side-effects when a user posts a chat message.
  #
  # Usage:
  #   Chat::MessageDispatcher.new(user: current_user, channel: channel, body: params[:body]).call
  #
  # Returns:
  #   Chat::MessageDispatcher::Result with:
  #     - message: ChatMessage that was persisted
  #     - command_executed?: always false; retained for callers that render a
  #       shared result shape
  class MessageDispatcher
    Result = Struct.new(:message, :command_executed?, keyword_init: true)

    def initialize(user:, channel:, body:, spam_throttler: nil)
      @user = user
      @channel = channel
      @body = body.to_s.strip
      @spam_throttler = spam_throttler
    end

    def call
      raise ArgumentError, "message cannot be blank" if body.blank?

      ensure_player_can_post!
      spam_throttler.check!
      ensure_privacy_respected!
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

    attr_reader :user, :channel, :body

    def ensure_player_can_post!
      user.ensure_social_features!

      membership = channel.memberships.find_by(user:)
      raise Chat::Errors::MutedError, "Muted in this channel" if membership&.muted?
    end

    def ensure_privacy_respected!
      return unless channel.whisper?

      target_id = whisper_target_id
      return unless target_id

      target = User.find_by(id: target_id)
      return unless target
      return if target.allows_chat_from?(user)

      raise Chat::Errors::PrivacyBlockedError, "#{target.profile_name} is not accepting whispers."
    end

    def whisper_target_id
      participant_ids = Array(channel.metadata["participant_ids"]).map(&:to_i)
      (participant_ids - [user.id]).first
    end

    def default_metadata
      {
        "channel_type" => channel.channel_type
      }
    end

    def spam_throttler
      @spam_throttler ||= Chat::SpamThrottler.new(user:, channel:)
    end
  end
end
