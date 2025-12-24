# frozen_string_literal: true

module Arena
  module TacticalCombat
    # Processes skill/ability usage in tactical combat.
    class SkillProcessor
      attr_reader :match, :character, :skill_id, :target_x, :target_y, :target_id

      def initialize(match:, character:, skill_id:, target_x: nil, target_y: nil, target_id: nil)
        @match = match
        @character = character
        @skill_id = skill_id
        @target_x = target_x
        @target_y = target_y
        @target_id = target_id
      end

      def execute!
        return {success: false, error: "Match is not active"} unless match.active?

        skill = find_skill
        return {success: false, error: "Skill not found"} unless skill

        participant = match.tactical_participants.find_by(character: character)
        return {success: false, error: "Participant not found"} unless participant
        return {success: false, error: "Not enough MP"} if participant.current_mp < skill.mp_cost.to_i

        result = execute_skill!(participant, skill)
        match.consume_action! if result[:success]

        result
      end

      private

      def find_skill
        # Find skill from character's abilities or skill nodes
        character.abilities.find_by(id: skill_id) ||
          Ability.joins(skill_node: :character_skills)
            .where(character_skills: {character_id: character.id})
            .find_by(id: skill_id)
      end

      def execute_skill!(participant, skill)
        case skill.skill_type
        when "damage"
          execute_damage_skill(participant, skill)
        when "heal"
          execute_heal_skill(participant, skill)
        when "buff"
          execute_buff_skill(participant, skill)
        when "aoe"
          execute_aoe_skill(participant, skill)
        else
          {success: false, error: "Unknown skill type"}
        end
      end

      def execute_damage_skill(participant, skill)
        target = find_target_participant
        return {success: false, error: "Target not found"} unless target

        # Check range
        distance = (participant.grid_x - target.grid_x).abs + (participant.grid_y - target.grid_y).abs
        skill_range = skill.metadata&.fetch("range", 3) || 3
        return {success: false, error: "Target out of range"} if distance > skill_range

        # Calculate and apply damage
        base_damage = skill.metadata&.fetch("base_damage", 20) || 20
        damage = base_damage + (character.stats.get(:intelligence).to_i / 2)
        actual_damage = target.take_damage!(damage)

        # Consume MP
        participant.update!(current_mp: participant.current_mp - skill.mp_cost)

        log_skill!(skill, "#{character.name} uses #{skill.name} on #{target.character.name} for #{actual_damage} damage!")

        {success: true, damage: actual_damage, target_defeated: !target.alive?}
      end

      def execute_heal_skill(participant, skill)
        target = target_id ? match.tactical_participants.find_by(character_id: target_id) : participant
        return {success: false, error: "Target not found"} unless target

        heal_amount = skill.metadata&.fetch("heal_amount", 30) || 30
        heal_amount += (character.stats.get(:spirit).to_i / 2)
        actual_heal = target.heal!(heal_amount)

        participant.update!(current_mp: participant.current_mp - skill.mp_cost)

        log_skill!(skill, "#{character.name} uses #{skill.name}, healing #{target.character.name} for #{actual_heal} HP!")

        {success: true, healed: actual_heal}
      end

      def execute_buff_skill(participant, skill)
        buff_key = skill.metadata&.fetch("buff_key", "attack_bonus")
        buff_value = skill.metadata&.fetch("buff_value", 10)
        duration = skill.metadata&.fetch("duration", 3)

        participant.add_buff!(buff_key, buff_value, duration: duration)
        participant.update!(current_mp: participant.current_mp - skill.mp_cost)

        log_skill!(skill, "#{character.name} uses #{skill.name}, gaining +#{buff_value} #{buff_key.humanize}!")

        {success: true, buff: buff_key, value: buff_value}
      end

      def execute_aoe_skill(participant, skill)
        return {success: false, error: "Target position required"} if target_x.nil? || target_y.nil?

        radius = skill.metadata&.fetch("radius", 1) || 1
        base_damage = skill.metadata&.fetch("base_damage", 15) || 15

        targets_hit = []
        match.tactical_participants.alive.each do |target|
          next if target == participant

          distance = (target.grid_x - target_x).abs + (target.grid_y - target_y).abs
          next if distance > radius

          damage = base_damage + (character.stats.get(:intelligence).to_i / 3)
          actual_damage = target.take_damage!(damage)
          targets_hit << {character: target.character.name, damage: actual_damage}
        end

        participant.update!(current_mp: participant.current_mp - skill.mp_cost)

        if targets_hit.any?
          log_skill!(skill, "#{character.name} uses #{skill.name}, hitting #{targets_hit.size} targets!")
        else
          log_skill!(skill, "#{character.name} uses #{skill.name}, but hits no one!")
        end

        {success: true, targets_hit: targets_hit}
      end

      def find_target_participant
        return nil unless target_id

        match.tactical_participants.alive.find_by(character_id: target_id)
      end

      def log_skill!(skill, message)
        match.tactical_combat_log_entries.create!(
          round_number: match.turn_number,
          sequence: match.tactical_combat_log_entries.where(round_number: match.turn_number).count + 1,
          log_type: "skill",
          message: "✨ #{message}",
          payload: {
            character_id: character.id,
            skill_id: skill.id,
            skill_name: skill.name
          }
        )
      end
    end
  end
end
