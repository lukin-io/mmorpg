# frozen_string_literal: true

module Game
  module Combat
    # Executes skills in combat, handling damage, healing, buffs, and effects.
    #
    # Works with both SkillNode (from skill trees) and Ability (from class).
    #
    # @example Execute a skill
    #   executor = Game::Combat::SkillExecutor.new(
    #     caster: character,
    #     target: enemy,
    #     skill: skill_node_or_ability,
    #     battle: battle
    #   )
    #   result = executor.execute!
    #
    class SkillExecutor
      Result = Struct.new(:success, :damage, :healing, :effects_applied, :message, :critical, keyword_init: true)

      SKILL_TYPES = {
        "damage" => :execute_damage,
        "heal" => :execute_heal,
        "buff" => :execute_buff,
        "debuff" => :execute_debuff,
        "dot" => :execute_dot,
        "hot" => :execute_hot,
        "aoe" => :execute_aoe,
        "drain" => :execute_drain,
        "shield" => :execute_shield
      }.freeze

      attr_reader :caster, :target, :skill, :battle, :errors

      def initialize(caster:, target:, skill:, battle:)
        @caster = caster
        @target = target
        @skill = skill
        @battle = battle
        @errors = []
      end

      # Execute the skill
      def execute!
        return failure("No skill provided") unless skill
        return failure("Caster is dead") if caster_dead?
        return failure("Not enough resources") unless can_afford_cost?
        return failure("Skill on cooldown") if on_cooldown?

        # Consume resources
        consume_resources!

        # Set cooldown
        set_cooldown!

        # Execute based on skill type
        skill_type = skill_effect_type
        handler = SKILL_TYPES[skill_type] || :execute_damage

        send(handler)
      end

      # Get character's available combat skills
      def self.available_skills(character)
        skills = []

        # Add class abilities
        if character.character_class
          character.character_class.abilities.where(kind: "active").each do |ability|
            skills << {
              id: "ability_#{ability.id}",
              source: :ability,
              record: ability,
              name: ability.name,
              type: ability.effects["type"] || "damage",
              cost: ability.resource_cost,
              cooldown: ability.cooldown_seconds,
              effects: ability.effects
            }
          end
        end

        # Add unlocked skill tree nodes (active type only)
        character.skill_nodes.where(node_type: "active").each do |node|
          skills << {
            id: "skill_#{node.id}",
            source: :skill_node,
            record: node,
            name: node.name,
            type: node.effects["type"] || "damage",
            cost: node.resource_cost,
            cooldown: node.cooldown_seconds,
            effects: node.effects
          }
        end

        skills
      end

      private

      def caster_dead?
        caster.respond_to?(:current_hp) && caster.current_hp <= 0
      end

      def can_afford_cost?
        cost = skill_cost
        return true if cost.empty?

        mp_cost = cost["mp"] || cost[:mp] || 0
        return caster.current_mp >= mp_cost if mp_cost.positive?

        true
      end

      def on_cooldown?
        cooldown_key = "skill_#{skill.id}_cooldown"
        last_used = battle.metadata&.dig("cooldowns", cooldown_key)
        return false unless last_used

        Time.parse(last_used) + skill_cooldown > Time.current
      end

      def consume_resources!
        cost = skill_cost
        mp_cost = cost["mp"] || cost[:mp] || 0

        if mp_cost.positive? && caster.respond_to?(:current_mp=)
          caster.current_mp = [caster.current_mp - mp_cost, 0].max
          caster.save! if caster.respond_to?(:save!)
        end
      end

      def set_cooldown!
        return if skill_cooldown.zero?

        cooldown_key = "skill_#{skill.id}_cooldown"
        battle.metadata ||= {}
        battle.metadata["cooldowns"] ||= {}
        battle.metadata["cooldowns"][cooldown_key] = Time.current.iso8601
        battle.save!
      end

      def skill_cost
        skill.respond_to?(:resource_cost) ? (skill.resource_cost || {}) : {}
      end

      def skill_cooldown
        skill.respond_to?(:cooldown_seconds) ? (skill.cooldown_seconds || 0) : 0
      end

      def skill_effects
        skill.respond_to?(:effects) ? (skill.effects || {}) : {}
      end

      def skill_effect_type
        effects = skill_effects
        effects["type"] || effects[:type] || "damage"
      end

      def skill_name
        skill.respond_to?(:name) ? skill.name : "Unknown Skill"
      end

      # Execute damage skill
      def execute_damage
        effects = skill_effects
        base_damage = effects["base_damage"] || effects[:base_damage] || 30
        scaling_stat = effects["scaling_stat"] || effects[:scaling_stat] || "intelligence"
        scaling_factor = effects["scaling_factor"] || effects[:scaling_factor] || 0.5

        # Calculate damage with stat scaling
        stat_value = caster_stat(scaling_stat)
        damage = base_damage + (stat_value * scaling_factor).to_i

        # Critical hit check
        crit_chance = caster_stat("luck") / 10 + 5
        is_critical = rand(100) < crit_chance
        damage = (damage * 1.5).to_i if is_critical

        # Apply damage
        apply_damage_to_target(damage)

        log_skill_use(damage, is_critical, "damage")

        Result.new(
          success: true,
          damage: damage,
          healing: 0,
          effects_applied: [],
          message: skill_message(damage, is_critical, "damage"),
          critical: is_critical
        )
      end

      # Execute heal skill
      def execute_heal
        effects = skill_effects
        base_heal = effects["base_heal"] || effects[:base_heal] || 40
        scaling_stat = effects["scaling_stat"] || effects[:scaling_stat] || "spirit"
        scaling_factor = effects["scaling_factor"] || effects[:scaling_factor] || 0.6

        stat_value = caster_stat(scaling_stat)
        healing = base_heal + (stat_value * scaling_factor).to_i

        # Apply healing to target (or self if no target)
        heal_target = target || caster
        apply_healing_to_target(heal_target, healing)

        log_skill_use(healing, false, "heal")

        Result.new(
          success: true,
          damage: 0,
          healing: healing,
          effects_applied: [],
          message: "#{caster.name} uses #{skill_name}, healing for #{healing} HP!",
          critical: false
        )
      end

      # Execute buff skill
      def execute_buff
        effects = skill_effects
        buff_stat = effects["buff_stat"] || effects[:buff_stat] || "strength"
        buff_value = effects["buff_value"] || effects[:buff_value] || 10
        duration = effects["duration"] || effects[:duration] || 3

        buff_target = target || caster
        apply_buff(buff_target, buff_stat, buff_value, duration)

        Result.new(
          success: true,
          damage: 0,
          healing: 0,
          effects_applied: [{type: "buff", stat: buff_stat, value: buff_value, duration: duration}],
          message: "#{caster.name} uses #{skill_name}, buffing #{buff_stat} by #{buff_value}!",
          critical: false
        )
      end

      # Execute debuff skill
      def execute_debuff
        effects = skill_effects
        debuff_stat = effects["debuff_stat"] || effects[:debuff_stat] || "defense"
        debuff_value = effects["debuff_value"] || effects[:debuff_value] || 10
        duration = effects["duration"] || effects[:duration] || 3

        apply_debuff(target, debuff_stat, debuff_value, duration)

        Result.new(
          success: true,
          damage: 0,
          healing: 0,
          effects_applied: [{type: "debuff", stat: debuff_stat, value: debuff_value, duration: duration}],
          message: "#{caster.name} uses #{skill_name}, reducing #{target&.name}'s #{debuff_stat} by #{debuff_value}!",
          critical: false
        )
      end

      # Execute damage over time
      def execute_dot
        effects = skill_effects
        tick_damage = effects["tick_damage"] || effects[:tick_damage] || 15
        duration = effects["duration"] || effects[:duration] || 3

        apply_dot(target, tick_damage, duration)

        Result.new(
          success: true,
          damage: 0,
          healing: 0,
          effects_applied: [{type: "dot", damage: tick_damage, duration: duration}],
          message: "#{caster.name} uses #{skill_name}, applying #{tick_damage} damage per turn for #{duration} turns!",
          critical: false
        )
      end

      # Execute heal over time
      def execute_hot
        effects = skill_effects
        tick_heal = effects["tick_heal"] || effects[:tick_heal] || 20
        duration = effects["duration"] || effects[:duration] || 3

        heal_target = target || caster
        apply_hot(heal_target, tick_heal, duration)

        Result.new(
          success: true,
          damage: 0,
          healing: 0,
          effects_applied: [{type: "hot", heal: tick_heal, duration: duration}],
          message: "#{caster.name} uses #{skill_name}, healing #{tick_heal} HP per turn for #{duration} turns!",
          critical: false
        )
      end

      # Execute AOE damage
      def execute_aoe
        effects = skill_effects
        base_damage = effects["base_damage"] || effects[:base_damage] || 20
        radius = effects["radius"] || effects[:radius] || 1

        # In PvE, AOE just hits the single target with reduced damage for now
        # Could be expanded for group fights
        damage = (base_damage * 0.8).to_i
        apply_damage_to_target(damage)

        log_skill_use(damage, false, "aoe")

        Result.new(
          success: true,
          damage: damage,
          healing: 0,
          effects_applied: [{type: "aoe", radius: radius}],
          message: "#{caster.name} uses #{skill_name}, dealing #{damage} AOE damage!",
          critical: false
        )
      end

      # Execute drain (damage + heal)
      def execute_drain
        effects = skill_effects
        base_damage = effects["base_damage"] || effects[:base_damage] || 25
        drain_percent = effects["drain_percent"] || effects[:drain_percent] || 50

        damage = base_damage + (caster_stat("intelligence") * 0.3).to_i
        healing = (damage * drain_percent / 100).to_i

        apply_damage_to_target(damage)
        apply_healing_to_target(caster, healing)

        log_skill_use(damage, false, "drain")

        Result.new(
          success: true,
          damage: damage,
          healing: healing,
          effects_applied: [{type: "drain"}],
          message: "#{caster.name} uses #{skill_name}, draining #{damage} HP and healing for #{healing}!",
          critical: false
        )
      end

      # Execute shield
      def execute_shield
        effects = skill_effects
        shield_amount = effects["shield_amount"] || effects[:shield_amount] || 50
        duration = effects["duration"] || effects[:duration] || 3

        shield_target = target || caster
        apply_shield(shield_target, shield_amount, duration)

        Result.new(
          success: true,
          damage: 0,
          healing: 0,
          effects_applied: [{type: "shield", amount: shield_amount, duration: duration}],
          message: "#{caster.name} uses #{skill_name}, creating a #{shield_amount} HP shield!",
          critical: false
        )
      end

      # Helper methods

      def caster_stat(stat_name)
        return 0 unless caster.respond_to?(:stats)

        stats = caster.stats
        stats.respond_to?(stat_name) ? stats.send(stat_name) : 0
      end

      def apply_damage_to_target(damage)
        return unless target.respond_to?(:current_hp=)

        target.current_hp = [target.current_hp - damage, 0].max
        target.save! if target.respond_to?(:save!)
      end

      def apply_healing_to_target(heal_target, healing)
        return unless heal_target.respond_to?(:current_hp=)

        max_hp = heal_target.respond_to?(:max_hp) ? heal_target.max_hp : 100
        heal_target.current_hp = [heal_target.current_hp + healing, max_hp].min
        heal_target.save! if heal_target.respond_to?(:save!)
      end

      def apply_buff(buff_target, stat, value, duration)
        apply_effect(buff_target, "buff", {stat: stat, value: value}, duration)
      end

      def apply_debuff(debuff_target, stat, value, duration)
        apply_effect(debuff_target, "debuff", {stat: stat, value: -value}, duration)
      end

      def apply_dot(dot_target, damage, duration)
        apply_effect(dot_target, "dot", {damage: damage}, duration)
      end

      def apply_hot(hot_target, heal, duration)
        apply_effect(hot_target, "hot", {heal: heal}, duration)
      end

      def apply_shield(shield_target, amount, duration)
        apply_effect(shield_target, "shield", {amount: amount, remaining: amount}, duration)
      end

      def apply_effect(effect_target, effect_type, data, duration)
        participant = battle.battle_participants.find_by(character: effect_target)
        return unless participant

        participant.combat_buffs ||= []
        participant.combat_buffs << {
          type: effect_type,
          data: data,
          duration: duration,
          applied_at: Time.current.iso8601
        }
        participant.save!
      end

      def log_skill_use(amount, critical, action_type)
        battle.combat_log_entries.create!(
          round_number: battle.round_number || 1,
          sequence: next_log_sequence,
          log_type: "skill",
          message: skill_message(amount, critical, action_type),
          payload: {
            caster_id: caster.id,
            target_id: target&.id,
            skill_id: skill.id,
            skill_name: skill_name,
            amount: amount,
            critical: critical,
            action_type: action_type
          }
        )
      end

      def next_log_sequence
        (battle.combat_log_entries.maximum(:sequence) || 0) + 1
      end

      def skill_message(amount, critical, action_type)
        case action_type
        when "damage", "aoe", "drain"
          if critical
            "💥 CRITICAL! #{caster.name} uses #{skill_name} on #{target&.name} for #{amount} damage!"
          else
            "✨ #{caster.name} uses #{skill_name} on #{target&.name} for #{amount} damage!"
          end
        when "heal"
          "💚 #{caster.name} uses #{skill_name}, healing for #{amount} HP!"
        else
          "✨ #{caster.name} uses #{skill_name}!"
        end
      end

      def failure(message)
        @errors << message
        Result.new(success: false, damage: 0, healing: 0, effects_applied: [], message: message, critical: false)
      end
    end
  end
end
