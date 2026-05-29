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

    # Broadcast a combat action.
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
            kills: p[:kills]
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
        participants: match.arena_participations.includes(:character, :npc_template).map do |p|
          participant_data(p)
        end
      })
    end

    # Build participant data hash for broadcast
    # Handles both player characters and NPCs
    #
    # @param p [ArenaParticipation] participation record
    # @return [Hash] participant data
    def participant_data(p)
      if p.npc?
        npc = p.npc_template
        {
          id: "npc-#{npc.id}",
          character_id: "npc-#{npc.id}",
          character_name: npc.name,
          team: p.team,
          level: npc.level,
          current_hp: p.current_hp || npc.health,
          max_hp: p.max_hp || npc.health,
          current_mp: 0,
          max_mp: 0,
          is_npc: true
        }
      else
        char = p.character
        {
          character_id: char.id,
          character_name: char.name,
          team: p.team,
          level: char.level,
          current_hp: char.current_hp,
          max_hp: char.max_hp,
          current_mp: char.current_mp,
          max_mp: char.max_mp,
          is_npc: false
        }
      end
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
    # @param opts [Hash] additional options:
    #   - critical: Boolean (whether it was a critical hit)
    #   - body_part: String (targeted body part)
    #   - attack_type: Symbol (:simple, :aimed)
    #   - block_parts: Array[String] (body parts being blocked)
    #   - npc_target: String (NPC name if target is NPC)
    def broadcast_combat_action(actor, action_type, target, damage, **opts)
      critical = opts.fetch(:critical, false)
      miss = opts.fetch(:miss, false)
      dodge = opts.fetch(:dodge, false)
      body_part = opts[:body_part]
      attack_type = opts[:attack_type]
      block_parts = opts[:block_parts]
      npc_target = opts[:npc_target]

      broadcast_action({
        actor_id: actor.id,
        actor_name: actor.name,
        target_id: target&.id,
        target_name: target&.name || npc_target,
        action_type: action_type,
        damage: damage,
        is_critical: critical,
        is_miss: miss || dodge,
        body_part: body_part,
        attack_type: attack_type,
        block_parts: block_parts,
        description: format_combat_description(actor, action_type, target, damage, body_part:, critical:, miss:, dodge:)
      }.compact)
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

    # Broadcast AP (Action Points) update for a character
    #
    # @param character [Character] the character
    # @param current_ap [Integer] current AP remaining
    # @param max_ap [Integer] maximum AP per turn
    def broadcast_ap_update(character, current_ap, max_ap)
      broadcast({
        type: "ap_update",
        character_id: character.id,
        character_name: character.name,
        current_ap: current_ap,
        max_ap: max_ap,
        ap_percent: ((current_ap.to_f / max_ap) * 100).round,
        timestamp: Time.current.strftime("%H:%M:%S")
      })
    end

    # Broadcast match ended
    #
    # @param winning_team [String, nil] the winning team or nil for draw
    # @param reason [Symbol] reason for ending (:normal, :timeout, :forfeit)
    def broadcast_match_ended(winning_team, reason: :normal)
      broadcast_result({
        winning_team: winning_team,
        reason: reason,
        timed_out: reason == :timeout,
        participants: match.arena_participations.includes(:character, :npc_template).map do |p|
          participant_result_data(p)
        end,
        rewards: []
      })
    end

    # Build participant result data for match end broadcast
    # Handles both player characters and NPCs
    #
    # @param p [ArenaParticipation] participation record
    # @return [Hash] participant result data
    def participant_result_data(p)
      if p.npc?
        npc = p.npc_template
        {
          character_id: "npc-#{npc.id}",
          character_name: npc.name,
          team: p.team,
          result: p.result,
          damage_dealt: p.metadata&.dig("damage_dealt") || 0,
          damage_taken: p.metadata&.dig("damage_taken") || 0,
          kills: p.metadata&.dig("kills") || 0,
          is_npc: true
        }
      else
        {
          character_id: p.character_id,
          character_name: p.character&.name,
          team: p.team,
          result: p.result,
          damage_dealt: p.metadata&.dig("damage_dealt") || 0,
          damage_taken: p.metadata&.dig("damage_taken") || 0,
          kills: p.metadata&.dig("kills") || 0,
          is_npc: false
        }
      end
    end

    # Broadcast system message for combat warnings or status changes.
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

    def broadcast_timeout_claim_available
      broadcast({
        type: "timeout_claim_available",
        message: "Timeout finish is available.",
        turn_number: match.current_turn_number,
        timestamp: Time.current.strftime("%H:%M:%S")
      })
    end

    private

    def broadcast(data)
      ActionCable.server.broadcast(
        match.broadcast_channel,
        data.merge(match_id: match.id)
      )
    end

    def countdown_message(seconds)
      case seconds
      when 0
        "Fight started"
      when 1..3
        seconds.to_s
      when 4..10
        "Fight starts in: #{seconds}"
      else
        "Fight starts in #{seconds}s"
      end
    end

    def format_action_result(action)
      parts = []

      if action[:is_miss]
        parts << "Miss"
      elsif action[:is_critical]
        parts << "Critical"
      end

      if action[:damage]
        parts << "-#{action[:damage]} HP"
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

    def format_combat_description(actor, action_type, target, damage, body_part: nil, critical: false, miss: false, dodge: false)
      target_name = target&.name || "opponent"

      case action_type.to_s
      when "miss"
        part_text = body_part ? " (#{body_part})" : ""
        "#{actor.name} misses #{target_name}#{part_text}."
      when "dodge"
        part_text = body_part ? " (#{body_part})" : ""
        "#{target_name} dodges #{actor.name}#{part_text}."
      when "attack"
        if miss || dodge
          part_text = body_part ? " (#{body_part})" : ""
          return dodge ? "#{target_name} dodges #{actor.name}#{part_text}." : "#{actor.name} misses #{target_name}#{part_text}."
        end

        if damage
          part_text = body_part ? " (#{body_part})" : ""
          crit_text = critical ? " Critical hit!" : ""
          "#{actor.name} hits #{target_name}#{part_text}: #{damage} damage.#{crit_text}"
        else
          "#{actor.name} attacks."
        end
      when "blocked"
        part_text = body_part ? " (#{body_part})" : ""
        "#{target_name} blocks #{actor.name}'s attack#{part_text}."
      when "defend"
        "#{actor.name} defends."
      else
        "#{actor.name}: #{action_type}."
      end
    end
  end
end
