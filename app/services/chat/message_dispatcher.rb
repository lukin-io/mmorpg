# frozen_string_literal: true

module Chat
  # Coordinates the compact Neverlands-style chat post path.
  class MessageDispatcher
    Result = Struct.new(:message, :command_executed?, keyword_init: true)

    def initialize(user:, channel:, body:, context_key: nil, session: nil)
      @user = user
      @channel = channel
      @body = body.to_s.strip
      @context_key = context_key
      @session = session
    end

    def call
      raise ArgumentError, "message cannot be blank" if body.blank?

      if channel.local?
        character = user.character
        raise Pundit::NotAuthorizedError, "Current location required" unless character

        character.with_lock do
          unless session&.persisted? && session.user_id == user.id
            raise Pundit::NotAuthorizedError, "Active login required"
          end
          session.lock!
          raise Pundit::NotAuthorizedError, "Active login required" if session.signed_out_at

          persist_message
        end
      else
        persist_message
      end
    end

    private

    attr_reader :user, :channel, :body, :context_key, :session

    def persist_message
      ensure_player_can_post!
      ensure_channel_access!
      ensure_privacy_respected!

      message = channel.chat_messages.create!(
        sender: user,
        body: body,
        metadata: default_metadata
      )

      Result.new(message:, command_executed?: false)
    end

    def ensure_player_can_post!
      user.ensure_social_features!
      raise Chat::Errors::MutedError, "System chat is read-only." if channel.system?

      return unless user.respond_to?(:chat_muted_until)
      return unless user.chat_muted_until.present? && user.chat_muted_until.future?

      raise Chat::Errors::MutedError, "You cannot post in chat."
    end

    def ensure_channel_access!
      unless ChatMessagePolicy.new(user, channel).create?
        raise Pundit::NotAuthorizedError, "Chat is unavailable at your current location"
      end
      return unless channel.local?

      if body.match?(/\A%<[^>]+>/)
        raise ArgumentError, "Private messaging is not available here."
      end
      current = LocalContext.new(character: user.character).synchronize!
      if context_key.present? && context_key != current&.key
        raise Pundit::NotAuthorizedError, "Chat location changed; refresh before sending"
      end
    end

    def ensure_privacy_respected!
      return unless channel.whisper?

      target_id = whisper_target_id
      return unless target_id

      target = User.find_by(id: target_id)
      return unless target
      return if Chat::IgnoreFilter.can_view_messages?(target, user)

      raise Chat::Errors::PrivacyBlockedError, "#{target.profile_name} does not accept private messages."
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
