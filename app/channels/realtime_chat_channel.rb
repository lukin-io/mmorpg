# frozen_string_literal: true

# Global chat channel for real-time messaging
# Supports multiple chat channels (global, local, clan, party)
#
# @example Subscribe to global chat
#   consumer.subscriptions.create({ channel: "RealtimeChatChannel", chat_type: "global" })
#
# @example Subscribe to a specific chat channel
#   consumer.subscriptions.create({ channel: "RealtimeChatChannel", chat_channel_id: 1 })
#
class RealtimeChatChannel < ApplicationCable::Channel
  CHAT_TYPES = %w[global local clan party whisper].freeze

  def subscribed
    reject unless current_user

    @chat_type = params[:chat_type] || "global"
    @chat_channel_record_id = params[:chat_channel_id]

    if @chat_channel_record_id.present?
      @chat_channel_record_record = ::ChatChannel.find_by(id: @chat_channel_record_id)
      if @chat_channel_record_record && can_access_channel?(@chat_channel_record_record)
        stream_from "chat:channel:#{@chat_channel_record.id}"
      else
        reject
      end
    else
      # Subscribe to global or type-specific chat
      stream_from "chat:#{@chat_type}"

      # Also subscribe to user-specific channel for whispers
      stream_from "chat:whisper:#{current_user.id}"
    end

    # Notify presence
    broadcast_user_joined
  end

  def unsubscribed
    stop_all_streams
    broadcast_user_left
  end

  # Send a chat message
  #
  # @param data [Hash] message data with :content, :recipient_id (optional), :prefix (optional)
  def speak(data)
    content = data["content"].to_s.strip
    return if content.blank?

    # Parse chat prefix commands
    parsed = parse_chat_command(content)

    case parsed[:type]
    when :whisper
      send_whisper(parsed[:target], parsed[:content])
    when :clan
      send_clan_message(parsed[:content])
    when :party
      send_party_message(parsed[:content])
    when :shout
      send_shout(parsed[:content])
    else
      send_message(content)
    end
  end

  # Request chat history
  def history(data)
    limit = [data["limit"].to_i, 100].min
    limit = 50 if limit <= 0

    messages = if @chat_channel_record
      @chat_channel_record.chat_messages.recent.limit(limit)
    else
      ChatMessage.where(chat_type: @chat_type).recent.limit(limit)
    end

    transmit({
      type: "chat_history",
      messages: messages.map { |m| format_message(m) }
    })
  end

  # Set chat mode (for client UI)
  def set_mode(data)
    mode = data["mode"]
    return unless %w[all private none].include?(mode)

    transmit({type: "mode_changed", mode: mode})
  end

  private

  def broadcast_user_joined
    broadcast_presence("user_joined")
  end

  def broadcast_user_left
    broadcast_presence("user_left")
  end

  def broadcast_presence(event)
    return unless current_user.character

    ActionCable.server.broadcast("chat:#{@chat_type}", {
      type: event,
      user_id: current_user.id,
      character_name: current_user.character.name,
      level: current_user.character.level
    })
  end

  def send_message(content)
    content = process_emoji(content)

    message = create_message(content)
    return unless message

    broadcast_message(message)
  end

  def send_whisper(target_name, content)
    target = User.joins(:characters).find_by(characters: {name: target_name})
    return transmit_error("User not found: #{target_name}") unless target
    return transmit_error("Cannot whisper yourself") if target == current_user

    content = process_emoji(content)
    message = create_message(content, recipient: target, chat_type: "whisper")
    return unless message

    # Send to both sender and recipient
    ActionCable.server.broadcast("chat:whisper:#{current_user.id}", {
      type: "whisper_sent",
      message: format_message(message)
    })

    ActionCable.server.broadcast("chat:whisper:#{target.id}", {
      type: "whisper_received",
      message: format_message(message)
    })
  end

  def send_clan_message(content)
    character = current_user.character
    return transmit_error("You are not in a clan") unless character&.clan

    content = process_emoji(content)
    message = create_message(content, chat_type: "clan", clan: character.clan)
    return unless message

    ActionCable.server.broadcast("chat:clan:#{character.clan.id}", {
      type: "clan_message",
      message: format_message(message)
    })
  end

  def send_party_message(content)
    character = current_user.character
    return transmit_error("You are not in a party") unless character&.current_party

    content = process_emoji(content)
    message = create_message(content, chat_type: "party", party: character.current_party)
    return unless message

    ActionCable.server.broadcast("chat:party:#{character.current_party.id}", {
      type: "party_message",
      message: format_message(message)
    })
  end

  def send_shout(content)
    character = current_user.character
    return transmit_error("You need level 5 to shout") unless character&.level.to_i >= 5

    content = process_emoji(content)
    message = create_message(content, chat_type: "shout")
    return unless message

    ActionCable.server.broadcast("chat:global", {
      type: "shout",
      message: format_message(message)
    })
  end

  def create_message(content, **options)
    ChatMessage.create(
      user: current_user,
      sender: current_user.character,
      chat_channel_id: @chat_channel_record&.id,
      content: content,
      chat_type: options[:chat_type] || @chat_type,
      recipient: options[:recipient],
      metadata: {
        sender_level: current_user.character&.level,
        sender_title: current_user.character&.current_title
      }
    )
  rescue ActiveRecord::RecordInvalid => e
    transmit_error("Could not send message: #{e.message}")
    nil
  end

  def broadcast_message(message)
    channel = @chat_channel_record ? "chat:channel:#{@chat_channel_record.id}" : "chat:#{@chat_type}"

    ActionCable.server.broadcast(channel, {
      type: "new_message",
      message: format_message(message)
    })
  end

  def format_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.user_id,
      sender_name: message.sender&.name || "System",
      sender_level: message.metadata&.dig("sender_level"),
      sender_title: message.metadata&.dig("sender_title"),
      chat_type: message.chat_type,
      timestamp: message.created_at.strftime("%H:%M"),
      full_timestamp: message.created_at.iso8601
    }
  end

  def parse_chat_command(content)
    case content
    when /^\/w\s+(\S+)\s+(.+)$/i, /^%(\S+)%\s*(.+)$/i
      {type: :whisper, target: ::Regexp.last_match(1), content: ::Regexp.last_match(2)}
    when /^%clan%\s*(.+)$/i, /^\/clan\s+(.+)$/i
      {type: :clan, content: ::Regexp.last_match(1)}
    when /^%party%\s*(.+)$/i, /^\/party\s+(.+)$/i
      {type: :party, content: ::Regexp.last_match(1)}
    when /^\/shout\s+(.+)$/i, /^!(.+)$/
      {type: :shout, content: ::Regexp.last_match(1)}
    else
      {type: :normal, content: content}
    end
  end

  def process_emoji(content)
    # Convert :NNN: emoji codes to Unicode or image tags
    content.gsub(/:(\d{3}):/) do |match|
      emoji_code = ::Regexp.last_match(1)
      ChatEmoji.find_by(code: emoji_code)&.html || match
    end
  end

  def can_access_channel?(channel)
    return false unless current_user
    return false if user_muted?

    case channel.channel_type
    when "global"
      # Global chat is accessible to all authenticated users
      true
    when "local"
      # Local chat is accessible to all authenticated users
      true
    when "arena"
      # Arena chat is accessible to all authenticated users
      true
    when "guild"
      # Guild chat requires guild membership
      user_in_guild?(channel)
    when "clan"
      # Clan chat requires clan membership
      user_in_clan?(channel)
    when "party"
      # Party chat requires party membership
      user_in_party?(channel)
    when "whisper"
      # Whisper channels require being a participant
      user_in_whisper?(channel)
    when "system"
      # System channels are read-only, accessible to all
      true
    else
      # Unknown channel type - check explicit membership
      channel.memberships.exists?(user: current_user)
    end
  end

  def user_muted?
    return false unless current_user.respond_to?(:chat_muted_until)

    current_user.chat_muted_until.present? && current_user.chat_muted_until > Time.current
  end

  def user_in_guild?(channel)
    # Extract guild ID from channel metadata or name
    guild_id = channel.metadata&.dig("guild_id")
    return false unless guild_id

    # Check if user has a character in this guild
    current_user.characters.exists?(guild_id: guild_id)
  end

  def user_in_clan?(channel)
    # Extract clan ID from channel metadata
    clan_id = channel.metadata&.dig("clan_id")
    return false unless clan_id

    # Check if user has a character in this clan
    current_user.characters.exists?(clan_id: clan_id)
  end

  def user_in_party?(channel)
    # Extract party ID from channel metadata
    party_id = channel.metadata&.dig("party_id")
    return false unless party_id

    # Check if user's active character is in this party
    active_character = current_user.characters.find_by(active: true)
    return false unless active_character

    PartyMembership.exists?(party_id: party_id, character: active_character)
  end

  def user_in_whisper?(channel)
    # Whisper channels have exactly 2 participants stored in metadata
    participants = channel.metadata&.dig("participants") || []
    participants.include?(current_user.id)
  end

  def can_send_to_channel?(channel)
    # Additional check before sending messages
    return false unless can_access_channel?(channel)
    return false if user_muted?
    return false if channel.system? # Can't send to system channels

    # Check if user is ignored by recipient (for whisper)
    if channel.whisper?
      recipient_id = (channel.metadata&.dig("participants") || []).find { |id| id != current_user.id }
      return false if user_ignored_by?(recipient_id)
    end

    true
  end

  def user_ignored_by?(user_id)
    return false unless user_id

    IgnoreListEntry.exists?(user_id: user_id, ignored_user_id: current_user.id)
  end

  def transmit_error(message)
    transmit({type: "error", message: message})
  end
end
