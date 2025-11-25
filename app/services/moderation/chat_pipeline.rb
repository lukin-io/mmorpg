# frozen_string_literal: true

module Moderation
  # ChatPipeline centralizes pre-send social checks (verification, mute/ignore rules, spam throttling).
  #
  # Usage:
  #   result = Moderation::ChatPipeline.new(
  #     user: current_user,
  #     channel: channel,
  #     input: params[:body],
  #     moderation_handler: Chat::Moderation::CommandHandler.new,
  #     spam_throttler: Chat::SpamThrottler.new(user:, channel:)
  #   ).call
  #
  # Returns:
  #   Result struct with:
  #     - command_executed?: Boolean
  #     - system_message: optional String when a GM command handled the input
  class ChatPipeline
    Result = Struct.new(:command_executed?, :system_message, keyword_init: true)

    def initialize(user:, channel:, input:, moderation_handler:, spam_throttler:)
      @user = user
      @channel = channel
      @input = input.to_s
      @moderation_handler = moderation_handler
      @spam_throttler = spam_throttler
    end

    def call
      ensure_player_can_post!
      spam_throttler.check!
      ensure_privacy_respected!

      command_result = moderation_handler.call(user:, channel:, input:)
      if command_result&.handled?
        Result.new(command_executed?: true, system_message: command_result.system_message)
      else
        Result.new(command_executed?: false)
      end
    end

    private

    attr_reader :user, :channel, :input, :moderation_handler, :spam_throttler

    def ensure_player_can_post!
      user.ensure_social_features!

      if ChatModerationAction.muting?(user:, channel:)
        raise Chat::Errors::MutedError, "You are muted in this channel."
      end

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
  end
end
