# frozen_string_literal: true

module Chat
  # Resolves source-backed chat channel contexts.
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
      when :arena
        arena_channel(context)
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

    def local_channel(_context)
      local = LocalContext.new(character: user.character).synchronize!
      raise Pundit::NotAuthorizedError, "Current location required" unless local

      slug = "local-#{local.key}"
      existing = ChatChannel.find_by(slug:)
      return existing if existing

      ChatChannel.create_or_find_by!(slug:) do |channel|
        channel.name = "Local"
        channel.channel_type = :local
        channel.system_owned = true
        channel.metadata = {"location_key" => local.key}
      end
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.errors.of_kind?(:slug, :taken)

      ChatChannel.find_by!(slug:)
    end

    def whisper_channel(context)
      participant_ids = Array(context[:participant_ids]).map(&:to_i).sort
      unless participant_ids.size == 2 && participant_ids.include?(user.id)
        raise ArgumentError, "private channels require exactly two participants"
      end

      slug = "whisper-#{participant_ids.join("-")}"
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

    def arena_channel(context)
      match_id = context.fetch(:arena_match_id)
      participant_ids = Array(context[:participant_ids]).presence ||
        ArenaMatch.find(match_id).arena_participations.pluck(:user_id)
      slug = "arena-#{match_id}"

      ChatChannel.find_or_create_by!(slug:) do |channel|
        channel.name = "Arena Match ##{match_id}"
        channel.channel_type = :arena
        channel.system_owned = true
        channel.metadata = {
          "arena_match_id" => match_id,
          "participant_ids" => participant_ids
        }
      end.tap do |channel|
        participant_ids.each do |participant_id|
          channel.memberships.find_or_create_by!(user_id: participant_id)
        end
      end
    end
  end
end
