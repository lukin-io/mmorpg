# frozen_string_literal: true

module Chat
  module Moderation
    # Parses GM chat commands (mute/unmute/ban) and applies moderation actions.
    #
    # Usage:
    #   result = Chat::Moderation::CommandHandler.new.call(
    #     user: current_user,
    #     channel: channel,
    #     input: params[:body]
    #   )
    #
    # Returns:
    #   Chat::Moderation::CommandHandler::Result with:
    #     - handled?: Boolean (true when a command was executed)
    #     - system_message: String summarizing the action for the chat log
    class CommandHandler
      Result = Struct.new(:handled?, :system_message, keyword_init: true)

      def initialize(now: -> { Time.current })
        @now = now
      end

      def call(user:, channel:, input:)
        return Result.new(handled?: false) unless input.to_s.start_with?("/gm")
        authorize!(user)

        tokens = input.delete_prefix("/gm").strip.split
        action = tokens.shift

        case action
        when "mute"
          handle_mute(user:, channel:, tokens:)
        when "unmute"
          handle_unmute(user:, tokens:)
        when "ban"
          handle_ban(user:, tokens:)
        else
          Result.new(handled?: false)
        end
      end

      private

      attr_reader :now

      def authorize!(user)
        return if user.has_any_role?(:gm, :admin)

        raise Chat::Errors::UnauthorizedCommandError, "GM privileges required"
      end

      def resolve_target(tokens)
        identifier = tokens.shift
        raise ArgumentError, "target user is required" if identifier.blank?

        User.find_by(id: identifier) || User.find_by(email: identifier) ||
          (raise ActiveRecord::RecordNotFound, "User #{identifier} not found")
      end

      def resolve_duration(tokens)
        minutes = Integer(tokens.shift || 0, exception: false)
        minutes = minutes.to_i
        minutes.positive? ? minutes : 30
      end

      def remaining_reason(tokens)
        tokens.join(" ").presence || "No reason provided"
      end

      def handle_mute(user:, channel:, tokens:)
        target = resolve_target(tokens)
        duration = resolve_duration(tokens)
        reason = remaining_reason(tokens)

        ChatModerationAction.create!(
          target_user: target,
          actor: user,
          action_type: channel.global? ? :mute_global : :mute_channel,
          expires_at: now.call + duration.minutes,
          context: {
            "reason" => reason,
            "chat_channel_id" => channel.id
          }
        )

        Result.new(
          handled?: true,
          system_message: "#{target.email} muted by #{user.email} for #{duration} minutes (#{reason})"
        )
      end

      def handle_unmute(user:, tokens:)
        target = resolve_target(tokens)

        ChatModerationAction
          .active
          .for_user(target)
          .destroy_all

        Result.new(
          handled?: true,
          system_message: "#{target.email} unmuted by #{user.email}"
        )
      end

      def handle_ban(user:, tokens:)
        target = resolve_target(tokens)
        duration = resolve_duration(tokens)
        reason = remaining_reason(tokens)

        ChatModerationAction.create!(
          target_user: target,
          actor: user,
          action_type: :ban_chat,
          expires_at: now.call + duration.minutes,
          context: {
            "reason" => reason
          }
        )

        Result.new(
          handled?: true,
          system_message: "#{target.email} chat-banned by #{user.email} for #{duration} minutes (#{reason})"
        )
      end
    end
  end
end
