# frozen_string_literal: true

module Chat
  module Errors
    class BaseError < StandardError; end

    # Raised when a player is muted or otherwise restricted from posting in a channel.
    class MutedError < BaseError; end

    # Raised when a user attempts a moderation command without the right role.
    class UnauthorizedCommandError < BaseError; end

    # Raised when a user exceeds the allowed chat rate.
    class SpamThrottledError < BaseError; end

    # Raised when the target player's privacy or ignore settings prevent messaging.
    class PrivacyBlockedError < BaseError; end
  end
end
