# frozen_string_literal: true

module Chat
  # Coordinates the compact Neverlands-style chat post path.
  class MessageDispatcher
    Result = Struct.new(:message, :command_executed?, keyword_init: true)

    def initialize(user:, channel:, body:)
      @user = user
      @channel = channel
      @body = body.to_s.strip
    end

    def call
      raise ArgumentError, "message cannot be blank" if body.blank?

      ensure_player_can_post!
      ensure_privacy_respected!
      channel.ensure_membership!(user)

      message = channel.chat_messages.create!(
        sender: user,
        body: body,
        metadata: default_metadata
      )

      Result.new(message:, command_executed?: false)
    end

    private

    attr_reader :user, :channel, :body

    def ensure_player_can_post!
      user.ensure_social_features!
      raise Chat::Errors::MutedError, "System chat is read-only." if channel.system?

      return unless user.respond_to?(:chat_muted_until)
      return unless user.chat_muted_until.present? && user.chat_muted_until.future?

      raise Chat::Errors::MutedError, "You are silenced in chat."
    end

    def ensure_privacy_respected!
      return unless channel.whisper?

      target_id = whisper_target_id
      return unless target_id

      target = User.find_by(id: target_id)
      return unless target
      return if Chat::IgnoreFilter.can_view_messages?(target, user)

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
  end
end
