# frozen_string_literal: true

module Arena
  module TacticalCombat
    # Processes attack actions in tactical combat.
    class AttackProcessor
      attr_reader :match, :attacker, :target_id

      def initialize(match:, attacker:, target_id:)
        @match = match
        @attacker = attacker
        @target_id = target_id
      end

      def execute!
        return {success: false, error: "Match is not active"} unless match.active?

        attacker_participant = match.tactical_participants.find_by(character: attacker)
        target_participant = match.tactical_participants.find_by(character_id: target_id)

        return {success: false, error: "Attacker not found"} unless attacker_participant
        return {success: false, error: "Target not found"} unless target_participant
        return {success: false, error: "Target is already defeated"} unless target_participant.alive?
        return {success: false, error: "Target out of range"} unless attacker_participant.can_attack?(target_participant)

        execute_attack!(attacker_participant, target_participant)
      end

      private

      def execute_attack!(attacker_p, target_p)
        # Calculate damage
        raw_damage = attacker_p.attack_damage
        is_critical = rand(100) < 15 # 15% crit chance
        damage = is_critical ? (raw_damage * 1.5).to_i : raw_damage

        # Apply damage
        actual_damage = target_p.take_damage!(damage)

        # Consume action
        match.consume_action!

        # Log the attack
        log_attack!(attacker_p, target_p, actual_damage, is_critical)

        {
          success: true,
          damage: actual_damage,
          critical: is_critical,
          target_defeated: !target_p.alive?,
          match_ended: match.completed?
        }
      end

      def log_attack!(attacker_p, target_p, damage, critical)
        message = if critical
          "💥 CRITICAL! #{attacker.name} deals #{damage} damage to #{target_p.character.name}!"
        else
          "⚔️ #{attacker.name} attacks #{target_p.character.name} for #{damage} damage."
        end

        message += " #{target_p.character.name} is defeated!" unless target_p.alive?

        match.tactical_combat_log_entries.create!(
          round_number: match.turn_number,
          sequence: match.tactical_combat_log_entries.where(round_number: match.turn_number).count + 1,
          log_type: "attack",
          message: message,
          payload: {
            attacker_id: attacker.id,
            target_id: target_p.character_id,
            damage: damage,
            critical: critical,
            target_hp_remaining: target_p.current_hp
          }
        )
      end
    end
  end
end
