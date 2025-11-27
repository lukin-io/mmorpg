# frozen_string_literal: true

module Arena
  # Real-time fight updates via ActionCable
  # Broadcasts countdown, combat actions, HP updates, and results
  #
  # @example Broadcast countdown
  #   broadcaster = Arena::CombatBroadcaster.new(match)
  #   broadcaster.broadcast_countdown(30)
  #
  # @example Broadcast combat action
  #   broadcaster.broadcast_action(action)
  #
  class CombatBroadcaster
    attr_reader :match

    def initialize(match)
      @match = match
    end

    # Broadcast countdown to match start
    #
    # @param seconds_remaining [Integer] seconds until fight starts
    def broadcast_countdown(seconds_remaining)
      broadcast({
        type: "countdown",
        seconds: seconds_remaining,
        message: countdown_message(seconds_remaining)
      })
    end

    # Broadcast a combat action (attack, skill, etc.)
    #
    # @param action [Hash] action details
    def broadcast_action(action)
      broadcast({
        type: "combat_action",
        timestamp: Time.current.strftime("%H:%M:%S"),
        actor_id: action[:actor_id],
        actor_name: action[:actor_name],
        target_id: action[:target_id],
        target_name: action[:target_name],
        action_type: action[:action_type],
        description: action[:description],
        damage: action[:damage],
        healing: action[:healing],
        is_critical: action[:is_critical],
        is_miss: action[:is_miss],
        result: format_action_result(action)
      })
    end

    # Broadcast HP/MP update for a participant
    #
    # @param participation [ArenaParticipation] the participant
    # @param character [Character] the character with updated vitals
    def broadcast_hp_update(participation, character)
      broadcast({
        type: "hp_update",
        character_id: character.id,
        team: participation.team,
        current_hp: character.current_hp,
        max_hp: character.max_hp,
        current_mp: character.current_mp,
        max_mp: character.max_mp,
        hp_percent: hp_percent(character),
        mp_percent: mp_percent(character),
        is_dead: character.current_hp <= 0
      })
    end

    # Broadcast match result
    #
    # @param result [Hash] result details
    def broadcast_result(result)
      broadcast({
        type: "match_result",
        winning_team: result[:winning_team],
        duration: match.duration,
        participants: result[:participants].map do |p|
          {
            character_id: p[:character_id],
            character_name: p[:character_name],
            team: p[:team],
            result: p[:result],
            damage_dealt: p[:damage_dealt],
            damage_taken: p[:damage_taken],
            healing_done: p[:healing_done],
            kills: p[:kills],
            rating_delta: p[:rating_delta]
          }
        end,
        rewards: result[:rewards]
      })
    end

    # Broadcast match start
    def broadcast_match_start
      broadcast({
        type: "match_start",
        match_id: match.id,
        participants: match.arena_participations.map do |p|
          {
            character_id: p.character_id,
            character_name: p.character.name,
            team: p.team,
            level: p.character.level,
            current_hp: p.character.current_hp,
            max_hp: p.character.max_hp,
            current_mp: p.character.current_mp,
            max_mp: p.character.max_mp
          }
        end
      })
    end

    # Alias for compatibility with CombatProcessor
    alias_method :broadcast_match_started, :broadcast_match_start

    # Broadcast vitals update for a character
    #
    # @param character [Character] the character with updated vitals
    def broadcast_vitals_update(character)
      participation = match.arena_participations.find_by(character:)
      return unless participation

      broadcast_hp_update(participation, character)
    end

    # Broadcast combat action from CombatProcessor
    #
    # @param actor [Character] the acting character
    # @param action_type [String] type of action
    # @param target [Character, nil] the target character
    # @param damage [Integer] damage dealt
    # @param critical [Boolean] whether it was a critical hit
    def broadcast_combat_action(actor, action_type, target, damage, critical: false)
      broadcast_action({
        actor_id: actor.id,
        actor_name: actor.name,
        target_id: target&.id,
        target_name: target&.name,
        action_type: action_type,
        damage: damage,
        is_critical: critical,
        description: format_combat_description(actor, action_type, target, damage)
      })
    end

    # Broadcast character defeat
    #
    # @param character [Character] the defeated character
    def broadcast_defeat(character)
      broadcast({
        type: "defeat",
        character_id: character.id,
        character_name: character.name,
        timestamp: Time.current.strftime("%H:%M:%S")
      })
    end

    # Broadcast match ended
    #
    # @param winning_team [String, nil] the winning team or nil for draw
    def broadcast_match_ended(winning_team)
      broadcast_result({
        winning_team: winning_team,
        participants: match.arena_participations.map do |p|
          {
            character_id: p.character_id,
            character_name: p.character.name,
            team: p.team,
            result: p.result,
            damage_dealt: p.metadata&.dig("damage_dealt") || 0,
            damage_taken: p.metadata&.dig("damage_taken") || 0,
            healing_done: p.metadata&.dig("healing_done") || 0,
            kills: p.metadata&.dig("kills") || 0,
            rating_delta: p.rating_delta
          }
        end,
        rewards: []
      })
    end

    # Broadcast system message (announcements, warnings)
    #
    # @param message [String] the message text
    # @param severity [Symbol] :info, :warning, :error
    def broadcast_system_message(message, severity: :info)
      broadcast({
        type: "system_message",
        message: message,
        severity: severity,
        timestamp: Time.current.strftime("%H:%M:%S")
      })
    end

    # Broadcast to spectators only
    #
    # @param data [Hash] the data to broadcast
    def broadcast_to_spectators(data)
      ActionCable.server.broadcast(
        "arena:spectate:#{match.spectator_code}",
        data.merge(match_id: match.id)
      )
    end

    private

    def broadcast(data)
      ActionCable.server.broadcast(
        match.broadcast_channel,
        data.merge(match_id: match.id)
      )

      # Also broadcast to spectators
      broadcast_to_spectators(data)
    end

    def countdown_message(seconds)
      case seconds
      when 0
        "FIGHT!"
      when 1..3
        seconds.to_s
      when 4..10
        "Get ready... #{seconds}"
      else
        "Match starts in #{seconds} seconds"
      end
    end

    def format_action_result(action)
      parts = []

      if action[:is_miss]
        parts << "MISS"
      elsif action[:is_critical]
        parts << "CRITICAL"
      end

      if action[:damage]
        parts << "-#{action[:damage]} HP"
      end

      if action[:healing]
        parts << "+#{action[:healing]} HP"
      end

      parts.join(" ")
    end

    def hp_percent(character)
      return 0 if character.max_hp.zero?
      ((character.current_hp.to_f / character.max_hp) * 100).round(1)
    end

    def mp_percent(character)
      return 0 if character.max_mp.zero?
      ((character.current_mp.to_f / character.max_mp) * 100).round(1)
    end

    def format_combat_description(actor, action_type, target, damage)
      case action_type.to_s
      when "attack"
        if target && damage.positive?
          "#{actor.name} strikes #{target.name} for #{damage} damage!"
        else
          "#{actor.name} attacks!"
        end
      when "defend"
        "#{actor.name} takes a defensive stance."
      when "skill"
        "#{actor.name} uses a skill!"
      else
        "#{actor.name} performs #{action_type}."
      end
    end
  end
end
