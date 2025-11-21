# frozen_string_literal: true

module Chat
  # Resolves the correct ChatChannel for a given context (global, local, guild, etc.)
  # and takes care of creating system-owned channels when necessary.
  #
  # Usage:
  #   channel = Chat::ChannelRouter.new(user: current_user).resolve(scope: :global)
  #
  # Returns:
  #   A ChatChannel record (persisted) that the caller can use for messaging.
  class ChannelRouter
    def initialize(user:)
      @user = user
    end

    def resolve(scope:, context: {})
      case scope.to_sym
      when :global
        global_channel
      when :local
        local_channel(context)
      when :guild
        scoped_channel(:guild, context.fetch(:guild_id))
      when :clan
        scoped_channel(:clan, context.fetch(:clan_id))
      when :party
        scoped_channel(:party, context.fetch(:party_id))
      when :private, :whisper
        whisper_channel(context)
      else
        raise ArgumentError, "Unknown chat scope: #{scope}"
      end
    end

    private

    attr_reader :user

    def global_channel
      ChatChannel.find_or_create_by!(slug: "global") do |channel|
        channel.name = "Global"
        channel.channel_type = :global
        channel.system_owned = true
      end
    end

    def local_channel(context)
      key = context.fetch(:local_key) { raise ArgumentError, "local_key is required" }
      slug = "local-#{key}"

      ChatChannel.find_or_create_by!(slug:) do |channel|
        channel.name = context[:name] || "Local (#{key})"
        channel.channel_type = :local
        channel.system_owned = true
        channel.metadata = {
          "local_key" => key,
          "label" => context[:name]
        }.compact
      end
    end

    def scoped_channel(type, identifier)
      slug = "#{type}-#{identifier}"
      ChatChannel.find_or_create_by!(slug:) do |channel|
        channel.name = "#{type.to_s.titleize} ##{identifier}"
        channel.channel_type = type
        channel.system_owned = true
        channel.metadata = {"#{type}_id" => identifier}
      end.tap do |channel|
        channel.ensure_membership!(user)
      end
    end

    def whisper_channel(context)
      participant_ids = Array(context[:participant_ids]).map(&:to_i).sort
      unless participant_ids.size == 2 && participant_ids.include?(user.id)
        raise ArgumentError, "private channels require exactly two participants"
      end

      slug = "whisper-#{participant_ids.join('-')}"
      ChatChannel.find_or_create_by!(slug:) do |channel|
        channel.name = "Private Whisper"
        channel.channel_type = :whisper
        channel.system_owned = false
        channel.metadata = {"participant_ids" => participant_ids}
      end.tap do |channel|
        participant_ids.each do |participant_id|
          channel.memberships.find_or_create_by!(user_id: participant_id)
        end
      end
    end
  end
end
