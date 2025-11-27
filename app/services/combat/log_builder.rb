# frozen_string_literal: true

module Combat
  # Builds structured combat log entries with proper typing and formatting.
  #
  # Log entry types mirror the combat log system:
  # - timestamp: Round/turn marker
  # - attack: Physical attack with body part
  # - skill: Ability/spell usage
  # - restoration: HP/MP recovery
  # - damage: Damage dealt (with element)
  # - block: Successful block
  # - miss: Missed attack
  # - status: Buff/debuff applied
  # - death: Participant defeated
  # - loot: Item/resource gained
  #
  # @example Build an attack log entry
  #   Combat::LogBuilder.attack(
  #     battle: battle,
  #     actor: attacker,
  #     target: defender,
  #     body_part: "head",
  #     damage: 45,
  #     element: "fire",
  #     critical: true
  #   )
  #
  class LogBuilder
    BODY_PARTS = %w[head torso stomach legs].freeze
    ELEMENTS = %w[normal fire water earth air arcane].freeze

    ELEMENT_COLORS = {
      "normal" => "#cccccc",
      "fire" => "#E80005",
      "water" => "#1C60C6",
      "earth" => "#8B4513",
      "air" => "#14BCE0",
      "arcane" => "#9932CC"
    }.freeze

    TEAM_COLORS = {
      "alpha" => "#0052A6",
      "beta" => "#087C20"
    }.freeze

    class << self
      # Create a timestamp/round marker entry
      def timestamp(battle:, round:, message: nil)
        create_entry(
          battle: battle,
          log_type: "timestamp",
          message: message || "Round #{round}",
          round_number: round,
          payload: {round: round}
        )
      end

      # Create an attack log entry
      def attack(battle:, actor:, target:, body_part:, damage:, element: "normal", critical: false, blocked: false)
        result_type = if blocked
          "blocked"
        else
          (critical ? "critical" : "hit")
        end

        message = format_attack_message(actor, target, body_part, damage, result_type, element)

        create_entry(
          battle: battle,
          log_type: "attack",
          actor: actor,
          target: target,
          damage_amount: damage,
          message: message,
          tags: [body_part, element, result_type].compact,
          payload: {
            body_part: body_part,
            element: element,
            critical: critical,
            blocked: blocked,
            result_type: result_type
          }
        )
      end

      # Create a skill usage log entry
      def skill(battle:, actor:, skill_name:, element: "arcane", target: nil, damage: 0, healing: 0)
        message = format_skill_message(actor, skill_name, element, target, damage, healing)

        create_entry(
          battle: battle,
          log_type: "skill",
          actor: actor,
          target: target,
          damage_amount: damage,
          healing_amount: healing,
          message: message,
          tags: ["skill", element].compact,
          payload: {
            skill_name: skill_name,
            element: element
          }
        )
      end

      # Create a restoration log entry (HP/MP recovery)
      def restoration(battle:, actor:, resource:, amount:, source: nil)
        message = format_restoration_message(actor, resource, amount, source)

        create_entry(
          battle: battle,
          log_type: "restoration",
          actor: actor,
          healing_amount: ((resource == "hp") ? amount : 0),
          message: message,
          tags: ["restoration", resource],
          payload: {
            resource: resource,
            amount: amount,
            source: source
          }
        )
      end

      # Create a miss entry
      def miss(battle:, actor:, target:, body_part:)
        message = "💨 #{actor_name(actor)}'s attack on #{actor_name(target)}'s #{body_part} misses!"

        create_entry(
          battle: battle,
          log_type: "miss",
          actor: actor,
          target: target,
          message: message,
          tags: ["miss", body_part],
          payload: {body_part: body_part}
        )
      end

      # Create a block entry
      def block(battle:, actor:, attacker:, body_part:, damage_reduced:)
        message = "🛡️ #{actor_name(actor)} blocks #{actor_name(attacker)}'s attack on #{body_part}! (#{damage_reduced} damage reduced)"

        create_entry(
          battle: battle,
          log_type: "block",
          actor: actor,
          target: attacker,
          message: message,
          tags: ["block", body_part],
          payload: {
            body_part: body_part,
            damage_reduced: damage_reduced
          }
        )
      end

      # Create a status effect entry
      def status(battle:, actor:, effect_name:, duration:, target: nil)
        affected = target || actor
        message = "✨ #{actor_name(actor)} applies «#{effect_name}» to #{actor_name(affected)} (#{duration} rounds)"

        create_entry(
          battle: battle,
          log_type: "status",
          actor: actor,
          target: target,
          message: message,
          tags: ["status", effect_name.parameterize],
          payload: {
            effect_name: effect_name,
            duration: duration
          }
        )
      end

      # Create a death entry
      def death(battle:, actor:, killer: nil)
        message = if killer
          "💀 #{actor_name(actor)} has been defeated by #{actor_name(killer)}!"
        else
          "💀 #{actor_name(actor)} has been defeated!"
        end

        create_entry(
          battle: battle,
          log_type: "death",
          actor: actor,
          target: killer,
          message: message,
          tags: ["death"],
          payload: {}
        )
      end

      # Create a loot entry
      def loot(battle:, actor:, item_name:, quantity: 1, skill_increased: nil)
        message = "🎁 #{actor_name(actor)} obtained «#{item_name}»"
        message += " x#{quantity}" if quantity > 1
        message += ". Skill «#{skill_increased}» increased!" if skill_increased

        create_entry(
          battle: battle,
          log_type: "loot",
          actor: actor,
          message: message,
          tags: ["loot"],
          payload: {
            item_name: item_name,
            quantity: quantity,
            skill_increased: skill_increased
          }
        )
      end

      # Create a system message entry
      def system(battle:, message:, tags: [])
        create_entry(
          battle: battle,
          log_type: "system",
          message: message,
          tags: ["system"] + tags,
          payload: {}
        )
      end

      private

      def create_entry(battle:, log_type:, message:, actor: nil, target: nil, damage_amount: 0, healing_amount: 0, tags: [], payload: {})
        round = battle.round_number || 1
        sequence = battle.next_sequence_for(round)

        entry = battle.combat_log_entries.create!(
          log_type: log_type,
          message: message,
          actor_id: actor_id(actor),
          actor_type: actor_type(actor),
          target_id: actor_id(target),
          target_type: actor_type(target),
          damage_amount: damage_amount,
          healing_amount: healing_amount,
          round_number: round,
          sequence: sequence,
          tags: tags,
          payload: payload.merge(
            actor_name: actor ? actor_name(actor) : nil,
            actor_team: actor_team(actor),
            target_name: target ? actor_name(target) : nil,
            target_team: actor_team(target)
          )
        )

        # Broadcast the new log entry
        broadcast_log_entry(battle, entry)

        entry
      end

      def actor_name(actor)
        return "Unknown" unless actor

        case actor
        when BattleParticipant
          actor.combatant_name
        when Character
          actor.name
        when NpcTemplate
          actor.name
        else
          actor.try(:name) || "Unknown"
        end
      end

      def actor_id(actor)
        return nil unless actor

        case actor
        when BattleParticipant
          actor.id
        when Character
          actor.id
        when NpcTemplate
          actor.id
        else
          actor.try(:id)
        end
      end

      def actor_type(actor)
        return nil unless actor

        case actor
        when BattleParticipant
          "BattleParticipant"
        when Character
          "Character"
        when NpcTemplate
          "NpcTemplate"
        else
          actor.class.name
        end
      end

      def actor_team(actor)
        return nil unless actor

        case actor
        when BattleParticipant
          actor.team
        end
      end

      def format_attack_message(actor, target, body_part, damage, result_type, element)
        actor_str = actor_name(actor)
        target_str = actor_name(target)
        element_str = (element != "normal") ? " (#{element})" : ""

        case result_type
        when "critical"
          "💥 CRITICAL! #{actor_str} strikes #{target_str}'s #{body_part} for #{damage} damage#{element_str}!"
        when "blocked"
          "🛡️ #{target_str} blocks #{actor_str}'s attack on #{body_part}! (#{damage} reduced damage)"
        else
          "⚔️ #{actor_str} hits #{target_str}'s #{body_part} for #{damage} damage#{element_str}."
        end
      end

      def format_skill_message(actor, skill_name, element, target, damage, healing)
        actor_str = actor_name(actor)
        ELEMENT_COLORS[element] || ELEMENT_COLORS["arcane"]

        if healing > 0
          "✨ #{actor_str} casts «#{skill_name}» — heals for #{healing} HP"
        elsif damage > 0
          target_str = target ? " on #{actor_name(target)}" : ""
          "✨ #{actor_str} casts «#{skill_name}»#{target_str} — #{damage} #{element} damage"
        else
          "✨ #{actor_str} uses «#{skill_name}»"
        end
      end

      def format_restoration_message(actor, resource, amount, source)
        actor_str = actor_name(actor)
        resource_label = (resource == "hp") ? "HP" : "MP"
        source_str = source ? " from «#{source}»" : ""

        "💚 #{actor_str} restored #{amount} #{resource_label}#{source_str}"
      end

      def broadcast_log_entry(battle, entry)
        ActionCable.server.broadcast(
          "battle_#{battle.id}",
          {
            type: "log_entry",
            entry: {
              id: entry.id,
              log_type: entry.log_type,
              message: entry.message,
              round_number: entry.round_number,
              sequence: entry.sequence,
              damage_amount: entry.damage_amount,
              healing_amount: entry.healing_amount,
              tags: entry.tags,
              payload: entry.payload,
              created_at: entry.created_at.iso8601
            }
          }
        )
      end
    end
  end
end
