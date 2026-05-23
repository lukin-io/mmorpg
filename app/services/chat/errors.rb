# frozen_string_literal: true

module Chat
  module Errors
    class BaseError < StandardError; end

    # Raised when a player is muted or otherwise restricted from posting in a channel.
    class MutedError < BaseError; end

    # Raised when the target player's privacy or ignore settings prevent messaging.
    class PrivacyBlockedError < BaseError; end
  end
end
