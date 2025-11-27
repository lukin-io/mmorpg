# frozen_string_literal: true

module Chat
  # Filters chat messages based on user ignore lists
  # Determines if a message should be visible to a given recipient
  #
  # @example Check if message is visible
  #   filter = Chat::IgnoreFilter.new(message, recipient)
  #   filter.visible? # => true/false
  #
  # @example Get filtered messages for user
  #   Chat::IgnoreFilter.filter_for_user(messages, user)
  #
  class IgnoreFilter
    attr_reader :message, :recipient

    # Initialize filter for a specific message and recipient
    #
    # @param message [ChatMessage] the message to check
    # @param recipient [User] the user who would receive the message
    def initialize(message, recipient)
      @message = message
      @recipient = recipient
    end

    # Check if the message should be visible to the recipient
    #
    # @return [Boolean] true if message should be shown
    def visible?
      return true if system_message?
      return true if gm_message?
      return true if same_user?
      return false if sender_ignored?
      return false if recipient_ignored_by_sender?

      true
    end

    # Check if message should be filtered (not visible)
    #
    # @return [Boolean] true if message should be hidden
    def filtered?
      !visible?
    end

    # Get reason for filtering (for debugging/logging)
    #
    # @return [Symbol, nil] reason or nil if not filtered
    def filter_reason
      return nil if visible?
      return :sender_ignored if sender_ignored?
      return :recipient_ignored if recipient_ignored_by_sender?

      :unknown
    end

    class << self
      # Filter a collection of messages for a specific user
      #
      # @param messages [ActiveRecord::Relation, Array<ChatMessage>] messages to filter
      # @param user [User] the recipient user
      # @return [Array<ChatMessage>] filtered messages
      def filter_for_user(messages, user)
        return messages if user.nil?

        # Preload ignore lists for efficiency
        ignored_user_ids = user.ignore_list_entries.pluck(:ignored_user_id)
        ignored_by_user_ids = IgnoreListEntry.where(ignored_user_id: user.id).pluck(:user_id)

        messages.reject do |message|
          next false if message.system? || message.gm_alert?
          next false if message.sender_id == user.id

          # Check if sender is in either ignore list
          ignored_user_ids.include?(message.sender_id) ||
            ignored_by_user_ids.include?(message.sender_id)
        end
      end

      # Get user IDs that should NOT receive a message from sender
      #
      # @param sender [User] the message sender
      # @return [Array<Integer>] user IDs that have ignored or are ignored by sender
      def excluded_recipient_ids(sender)
        return [] if sender.nil?

        # Users who have ignored the sender
        ignored_by = IgnoreListEntry.where(ignored_user_id: sender.id).pluck(:user_id)

        # Users the sender has ignored (mutual blocking)
        ignoring = sender.ignore_list_entries.pluck(:ignored_user_id)

        (ignored_by + ignoring).uniq
      end

      # Check if user A should see messages from user B
      #
      # @param viewer [User] the potential recipient
      # @param sender [User] the message sender
      # @return [Boolean] true if messages should be visible
      def can_view_messages?(viewer, sender)
        return true if viewer.nil? || sender.nil?
        return true if viewer.id == sender.id

        !viewer.ignoring?(sender) && !viewer.ignored_by?(sender)
      end
    end

    private

    def system_message?
      message.system? || message.visibility.to_s == "system"
    end

    def gm_message?
      message.gm_alert? || message.visibility.to_s == "gm_alert"
    end

    def same_user?
      return false if message.sender_id.nil? || recipient.nil?

      message.sender_id == recipient.id
    end

    def sender_ignored?
      return false if recipient.nil? || message.sender_id.nil?

      recipient.ignoring?(message.sender)
    end

    def recipient_ignored_by_sender?
      return false if recipient.nil? || message.sender_id.nil?

      recipient.ignored_by?(message.sender)
    end
  end
end
