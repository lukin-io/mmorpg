# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Resolves a complete combat turn with simultaneous action resolution.
    #
    # Inputs:
    #   - battle: Battle record with participants
    #   - rng: Random instance for deterministic results
    #   - config: Combat configuration (optional, loads from YAML)
    #
    # Returns:
    #   Result struct with :success, :log_entries, :hp_changes, :effects_applied, :battle_ended
    #
    # Usage:
    #   resolver = Game::Combat::TurnResolver.new(battle, rng: Random.new(123))
    #   result = resolver.resolve!
    #   result.log_entries.each { |entry| puts entry[:message] }
    #
    class TurnResolver
      Result = Struct.new(
        :success, :log_entries, :hp_changes, :mp_changes,
        :effects_applied, :battle_ended, :winner_team, :errors,
        keyword_init: true
      ) do
        # Alias for legacy compatibility
        def log
          log_entries&.map { |e| e.is_a?(Hash) ? e[:message] : e.to_s } || []
        end
      end

      BODY_PARTS = %w[head torso stomach legs].freeze

      def initialize(battle, rng: Random.new, config: nil)
        @battle = battle
        @rng = rng
        @config = config || load_config
        @log_entries = []
        @hp_changes = {}
        @mp_changes = {}
        @effects_applied = []
        @errors = []
      end

      # Resolve the complete turn for all participants
      #
      # @return [Result] resolution result
      def resolve!
        return failure("Battle not found") unless @battle
        return failure("Battle is not active") unless @battle.active?

        # Get participants with pending actions
        participants = @battle.battle_participants.alive.includes(:character, :npc_template)

        # 1. Process skills/magic first (buffs, heals, debuffs)
        process_skills(participants)

        # 2. Process attacks and blocks simultaneously
        process_combat(participants)

        # 3. Apply end-of-turn effects (DOT, regen, buff tick-down)
        process_end_of_turn_effects(participants)

        # 4. Check for battle end
        battle_ended, winner_team = check_battle_end

        # 5. Clear pending actions
        clear_pending_actions(participants)

        # 6. Advance turn
        @battle.increment!(:turn_number) unless battle_ended

        Result.new(
          success: @errors.empty?,
          log_entries: @log_entries,
          hp_changes: @hp_changes,
          mp_changes: @mp_changes,
          effects_applied: @effects_applied,
          battle_ended: battle_ended,
          winner_team: winner_team,
          errors: @errors
        )
      end

      # Generate NPC actions using AI
      #
      # @param participant [BattleParticipant] NPC participant
      # @return [Hash] generated actions { attacks:, blocks:, skills: }
      def generate_npc_actions(participant)
        return nil unless participant.npc_template

        npc = participant.npc_template
        behavior = npc.metadata&.dig("ai_behavior") || "balanced"
        hp_percent = (participant.current_hp.to_f / participant.max_hp * 100).round

        attacks = []
        blocks = []
        skills = []

        case behavior
        when "aggressive"
          # Attack multiple body parts
          attacks << generate_attack("head")
          attacks << generate_attack("torso") if @rng.rand(100) < 50
          # Rarely block
          blocks << generate_block("torso") if hp_percent < 20 && @rng.rand(100) < 30
        when "defensive"
          # Single attack, frequent blocking
          attacks << generate_attack(BODY_PARTS.sample(random: @rng))
          blocks << generate_block(BODY_PARTS.sample(random: @rng)) if hp_percent < 70 || @rng.rand(100) < 50
        when "balanced"
          # Moderate attacks and blocks
          attacks << generate_attack(BODY_PARTS.sample(random: @rng))
          attacks << generate_attack(BODY_PARTS.sample(random: @rng)) if @rng.rand(100) < 40
          blocks << generate_block(BODY_PARTS.sample(random: @rng)) if hp_percent < 50 || @rng.rand(100) < 30
        else
          # Default to single attack
          attacks << generate_attack("torso")
        end

        {attacks: attacks, blocks: blocks, skills: skills}
      end

      private

      def load_config
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        File.exist?(config_path) ? YAML.load_file(config_path) : default_config
      end

      def default_config
        {
          "defaults" => {
            "action_points_per_turn" => 80,
            "base_hit_chance" => 85,
            "base_block_chance" => 50,
            "critical_hit_chance" => 10,
            "critical_hit_multiplier" => 1.5
          },
          "body_parts" => {
            "head" => {"damage_multiplier" => 1.3},
            "torso" => {"damage_multiplier" => 1.0},
            "stomach" => {"damage_multiplier" => 1.1},
            "legs" => {"damage_multiplier" => 0.9}
          }
        }
      end

      def process_skills(participants)
        participants.each do |participant|
          skills = extract_pending_skills(participant)
          next if skills.blank?

          skills.each do |skill|
            result = execute_skill(participant, skill)
            @log_entries << result[:log_entry] if result[:log_entry]
          end
        end
      end

      def process_combat(participants)
        teams = participants.group_by(&:team)
        return if teams.size < 2

        team_alpha = teams["alpha"] || []
        team_beta = teams["beta"] || []

        # Process each attacker
        (team_alpha + team_beta).each do |attacker|
          next unless attacker.is_alive

          attacks = extract_pending_attacks(attacker)
          next if attacks.blank?

          # Determine defender team
          defenders = (attacker.team == "alpha") ? team_beta : team_alpha
          defenders = defenders.select(&:is_alive)
          next if defenders.empty?

          attacks.each do |attack|
            defender = select_target(defenders, attack)
            next unless defender

            resolve_attack(attacker, defender, attack)
          end
        end
      end

      def resolve_attack(attacker, defender, attack)
        body_part = attack[:body_part] || attack["body_part"] || "torso"
        action_key = attack[:action_key] || attack["action_key"] || "simple"
        element = attack[:element] || attack["element"] || :physical

        # Get defender's blocks
        blocks = extract_pending_blocks(defender)

        # Create formula instances
        hit_formula = Game::Formulas::HitFormula.new(rng: @rng)
        block_formula = Game::Formulas::BlockFormula.new(rng: @rng)
        crit_formula = Game::Formulas::CriticalFormula.new(rng: @rng)
        dodge_formula = Game::Formulas::DodgeFormula.new(rng: @rng)
        resistance_formula = Game::Formulas::ResistanceFormula.new(rng: @rng)

        # Get combatants (character or NPC)
        attacker_entity = attacker.character || attacker.npc_template
        defender_entity = defender.character || defender.npc_template

        # 1. Check dodge first
        dodge_result = dodge_formula.call(
          defender: defender_entity,
          attacker: attacker_entity,
          body_part: body_part,
          action_key: action_key
        )

        if dodge_result[:dodged]
          @log_entries << create_log_entry(
            :dodge,
            attacker,
            "#{attacker.combatant_name} attacks #{defender.combatant_name}'s #{body_part}, but #{defender.combatant_name} dodged!",
            {body_part: body_part, action: action_key}
          )
          return
        end

        # 2. Check hit
        hit_result = hit_formula.call(
          attacker: attacker_entity,
          defender: defender_entity,
          body_part: body_part,
          action_key: action_key
        )

        unless hit_result[:hit]
          @log_entries << create_log_entry(
            :miss,
            attacker,
            "#{attacker.combatant_name} attacks #{defender.combatant_name}'s #{body_part} but misses!",
            {body_part: body_part, action: action_key, roll: hit_result[:roll], chance: hit_result[:chance]}
          )
          return
        end

        # 3. Calculate base damage
        base_damage = calculate_base_damage(attacker, attacker_entity, action_key, element)

        # 4. Apply body part multiplier
        body_multiplier = @config.dig("body_parts", body_part, "damage_multiplier") || 1.0
        damage = (base_damage * body_multiplier).round

        # 5. Check critical hit
        crit_result = crit_formula.call(
          attacker: attacker_entity,
          defender: defender_entity,
          body_part: body_part,
          action_key: action_key
        )

        if crit_result[:critical]
          damage = (damage * crit_result[:multiplier]).round
        end

        # 6. Check block
        block_result = block_formula.call(
          attacker_body_part: body_part,
          defender_blocks: blocks,
          defender: defender_entity,
          attacker: attacker_entity
        )

        pre_block_damage = damage

        if block_result[:blocked]
          damage = (damage * (1 - block_result[:damage_reduction])).round
        elsif block_result[:partial]
          damage = (damage * (1 - block_result[:damage_reduction])).round
        end

        # 7. Apply resistance reduction (NEW!)
        resistance_result = resistance_formula.call(
          defender: defender_entity,
          damage: damage,
          element: element
        )
        final_damage = resistance_result[:final_damage]

        # Minimum damage of 1
        final_damage = [final_damage, 1].max

        # Track skill bonuses for log
        skill_bonuses = calculate_skill_bonuses_for_log(attacker_entity, defender_entity, element)

        # 8. Apply damage
        apply_damage(defender, final_damage, body_part)

        # 9. Log the result
        blocked = block_result[:blocked] || block_result[:partial]
        log_type = if crit_result[:critical]
          :critical
        else
          (blocked ? :blocked : :damage)
        end
        message = build_attack_message(attacker, defender, body_part, final_damage, crit_result[:critical], blocked, resistance_result)

        @log_entries << create_log_entry(
          log_type,
          attacker,
          message,
          {
            body_part: body_part,
            action: action_key,
            element: element,
            base_damage: base_damage,
            pre_block_damage: pre_block_damage,
            damage: final_damage,
            critical: crit_result[:critical],
            blocked: blocked,
            resistance_reduction: resistance_result[:reduction_percent],
            skill_bonuses: skill_bonuses,
            target_hp: defender.current_hp
          }
        )

        # 10. Check for death
        if defender.current_hp <= 0
          handle_defeat(defender)
        end
      end

      def calculate_base_damage(participant, entity, action_key, element = :physical)
        if participant.character
          attack_power = entity.respond_to?(:attack_power) ? entity.attack_power : extract_stat(entity, :attack)

          # Apply combat skill bonus based on element/attack type
          skill_bonus = 0
          if entity.respond_to?(:passive_skill_level)
            if elemental_attack?(element)
              # Apply elemental_magic skill for magic attacks (+50% at max)
              elemental_skill = entity.passive_skill_level(:elemental_magic)
              skill_bonus = (attack_power * elemental_skill / 100.0 * 0.5).round
            else
              # Apply melee_combat skill for physical attacks (+50% at max)
              melee_skill = entity.passive_skill_level(:melee_combat)
              skill_bonus = (attack_power * melee_skill / 100.0 * 0.5).round
            end
          end

          base = attack_power + skill_bonus + @rng.rand(1..10)

          # Apply aimed attack bonus
          attack_multiplier = @config.dig("attack_types", action_key.to_s, "damage_multiplier") || 1.0
          base = (base * attack_multiplier).round

          base
        else
          # NPC damage - also apply NPC passive skills if present
          npc = participant.npc_template
          base_damage = calculate_npc_base_damage(npc)

          # Apply NPC skill bonuses if they have passive skills
          if npc&.metadata&.dig("passive_skills")
            skills = npc.metadata["passive_skills"]
            if elemental_attack?(element)
              elemental_skill = (skills["elemental_magic"] || skills[:elemental_magic]).to_i
              base_damage += (base_damage * elemental_skill / 100.0 * 0.5).round
            else
              melee_skill = (skills["melee_combat"] || skills[:melee_combat]).to_i
              base_damage += (base_damage * melee_skill / 100.0 * 0.5).round
            end
          end

          base_damage
        end
      end

      def calculate_npc_base_damage(npc)
        damage_range = npc&.damage_range
        if damage_range.is_a?(Range)
          @rng.rand(damage_range)
        elsif npc&.metadata&.dig("base_damage")
          npc.metadata["base_damage"] + @rng.rand(1..5)
        else
          level = npc&.level || 1
          (level * 3) + @rng.rand(5..15)
        end
      end

      def elemental_attack?(element)
        return false if element.nil?

        elemental_types = %i[fire ice cold water lightning air earth arcane dark light nature]
        elemental_types.include?(element.to_sym)
      end

      def calculate_skill_bonuses_for_log(attacker_entity, defender_entity, element)
        bonuses = {}

        if attacker_entity.respond_to?(:passive_skill_level)
          if elemental_attack?(element)
            bonuses[:elemental_magic] = attacker_entity.passive_skill_level(:elemental_magic)
          else
            bonuses[:melee_combat] = attacker_entity.passive_skill_level(:melee_combat)
          end
          bonuses[:critical_strikes] = attacker_entity.passive_skill_level(:critical_strikes)
        end

        if defender_entity.respond_to?(:passive_skill_level)
          bonuses[:evasion] = defender_entity.passive_skill_level(:evasion)
          bonuses[:block_mastery] = defender_entity.passive_skill_level(:block_mastery)

          # Include resistance skill that was applied
          resistance_skill = Game::Formulas::ResistanceFormula::ELEMENT_TO_SKILL[element.to_sym] || :physical_fortitude
          bonuses[resistance_skill] = defender_entity.passive_skill_level(resistance_skill)
        end

        bonuses.compact
      end

      def apply_damage(participant, damage, body_part)
        new_hp = [participant.current_hp - damage, 0].max
        participant.update!(current_hp: new_hp, is_alive: new_hp > 0)

        # Track HP change
        @hp_changes[participant.id] ||= 0
        @hp_changes[participant.id] -= damage

        # Track body part damage
        body_damage = participant.body_damage || {}
        body_damage[body_part] = (body_damage[body_part] || 0) + damage
        participant.update!(body_damage: body_damage)

        # Update character HP if present
        if participant.character
          Characters::VitalsService.new(participant.character).apply_damage(damage, source: "combat")
        end
      end

      def handle_defeat(participant)
        participant.update!(is_alive: false)

        @log_entries << create_log_entry(
          :defeat,
          participant,
          "#{participant.combatant_name} has been defeated!",
          {}
        )
      end

      def execute_skill(participant, skill)
        skill_key = skill[:key] || skill["key"]
        magic_config = @config.dig("magic_types", skill_key) || {}

        participant.character || participant.npc_template

        # Deduct mana
        mana_cost = magic_config["mana_cost"].to_i
        if mana_cost > 0 && participant.current_mp >= mana_cost
          new_mp = participant.current_mp - mana_cost
          participant.update!(current_mp: new_mp)
          @mp_changes[participant.id] ||= 0
          @mp_changes[participant.id] -= mana_cost
        end

        case magic_config["effect"]
        when "heal_hp", "heal"
          amount = magic_config["amount"] || 30
          new_hp = [participant.current_hp + amount, participant.max_hp].min
          participant.update!(current_hp: new_hp)
          @hp_changes[participant.id] ||= 0
          @hp_changes[participant.id] += amount

          {
            log_entry: create_log_entry(
              :heal,
              participant,
              "#{participant.combatant_name} uses #{magic_config["name"]} and restores #{amount} HP!",
              {skill: skill_key, amount: amount}
            )
          }
        when "heal_mp"
          amount = magic_config["amount"] || 20
          new_mp = [participant.current_mp + amount, participant.max_mp].min
          participant.update!(current_mp: new_mp)
          @mp_changes[participant.id] ||= 0
          @mp_changes[participant.id] += amount

          {
            log_entry: create_log_entry(
              :restore_mp,
              participant,
              "#{participant.combatant_name} restores #{amount} MP!",
              {skill: skill_key, amount: amount}
            )
          }
        when "shield", "barrier"
          # Add defensive buff
          add_effect(participant, {
            type: "shield",
            name: magic_config["name"],
            duration: 2,
            damage_reduction: 0.5
          })

          {
            log_entry: create_log_entry(
              :buff,
              participant,
              "#{participant.combatant_name} activates #{magic_config["name"]}!",
              {skill: skill_key, effect: "shield"}
            )
          }
        else
          # Damage spell - would need target selection
          {log_entry: nil}
        end
      end

      def process_end_of_turn_effects(participants)
        participants.each do |participant|
          effects = participant.active_effects || []
          next if effects.empty?

          effects.each do |effect|
            case effect["type"]
            when "dot", "poison", "burn", "bleed"
              damage = effect["damage"] || 5
              apply_damage(participant, damage, "torso")
              @log_entries << create_log_entry(
                :dot,
                participant,
                "#{participant.combatant_name} takes #{damage} damage from #{effect["name"]}!",
                {effect: effect["name"], damage: damage}
              )
            when "regen", "heal_over_time"
              heal = effect["heal"] || 5
              new_hp = [participant.current_hp + heal, participant.max_hp].min
              participant.update!(current_hp: new_hp)
              @hp_changes[participant.id] ||= 0
              @hp_changes[participant.id] += heal
            end
          end

          # Tick down effect durations
          updated_effects = effects.map do |effect|
            effect["duration"] = (effect["duration"] || 1) - 1
            effect
          end.select { |e| e["duration"] > 0 }

          participant.update!(active_effects: updated_effects)
        end

        # MP regeneration
        participants.each do |participant|
          regen = (participant.max_mp * 0.05).round
          next if regen <= 0

          new_mp = [participant.current_mp + regen, participant.max_mp].min
          participant.update!(current_mp: new_mp)
          @mp_changes[participant.id] ||= 0
          @mp_changes[participant.id] += regen
        end
      end

      def check_battle_end
        teams = @battle.battle_participants.group_by(&:team)
        alive_teams = teams.select { |_team, members| members.any?(&:is_alive) }

        if alive_teams.size <= 1
          winner_team = alive_teams.keys.first
          @battle.update!(status: :completed, ended_at: Time.current)
          return [true, winner_team]
        end

        [false, nil]
      end

      def clear_pending_actions(participants)
        participants.update_all(
          pending_attacks: [],
          pending_blocks: [],
          pending_skills: []
        )
      end

      def extract_pending_attacks(participant)
        participant.pending_attacks || []
      end

      def extract_pending_blocks(participant)
        participant.pending_blocks || []
      end

      def extract_pending_skills(participant)
        participant.pending_skills || []
      end

      def select_target(defenders, attack)
        # Could be enhanced with targeting logic
        # For now, select lowest HP defender
        defenders.min_by(&:current_hp)
      end

      def add_effect(participant, effect)
        effects = participant.active_effects || []
        effects << effect
        participant.update!(active_effects: effects)
        @effects_applied << {participant_id: participant.id, effect: effect}
      end

      def generate_attack(body_part)
        action = %w[simple aimed].sample(random: @rng)
        {body_part: body_part, action_key: action}
      end

      def generate_block(body_part)
        {body_part: body_part, action_key: "#{body_part}_block"}
      end

      def extract_stat(entity, stat_name)
        return 0 unless entity

        if stat_name.to_sym == :attack && entity.respond_to?(:attack_power)
          entity.attack_power.to_i
        elsif stat_name.to_sym == :defense && entity.respond_to?(:defense)
          entity.defense.to_i
        elsif stat_name.to_sym == :defense && entity.respond_to?(:defense_value)
          entity.defense_value.to_i
        elsif entity.respond_to?(:combat_stat)
          entity.combat_stat(stat_name).to_i
        elsif entity.respond_to?(:stats) && entity.stats.respond_to?(:get)
          entity.stats.get(stat_name).to_i
        elsif entity.respond_to?(stat_name)
          entity.public_send(stat_name).to_i
        else
          10 # Default
        end
      end

      def build_attack_message(attacker, defender, body_part, damage, critical, blocked, resistance_result = nil)
        prefix = critical ? "💥 CRITICAL! " : ""
        block_text = blocked ? " (BLOCKED)" : ""
        resist_text = ""

        if resistance_result && resistance_result[:reduction_percent].to_f > 0
          resist_text = " [#{resistance_result[:reduction_percent]}% resisted]"
        end

        "#{prefix}#{attacker.combatant_name} hits #{defender.combatant_name}'s #{body_part} for #{damage} damage#{block_text}#{resist_text}!"
      end

      def create_log_entry(log_type, participant, message, data)
        {
          round: @battle.turn_number,
          type: log_type,
          actor_id: participant.id,
          actor_name: participant.combatant_name,
          message: message,
          data: data,
          timestamp: Time.current.strftime("%H:%M:%S")
        }
      end

      def failure(message)
        @errors << message
        Result.new(
          success: false,
          log_entries: [],
          hp_changes: {},
          mp_changes: {},
          effects_applied: [],
          battle_ended: false,
          winner_team: nil,
          errors: @errors
        )
      end
    end
  end
end
