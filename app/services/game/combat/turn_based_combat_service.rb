# frozen_string_literal: true

module Game
  module Combat
    # Turn-based combat service with body-part targeting.
    #
    # Handles body-part targeting, action points, blocking, and magic.
    #
    # @example Start combat
    #   service = Game::Combat::TurnBasedCombatService.new(battle)
    #   service.submit_turn(character, attacks: [...], blocks: [...], skills: [...])
    #
    class TurnBasedCombatService
      Result = Struct.new(:success, :battle, :log_entries, :message, :round_complete, keyword_init: true)

      BODY_PARTS = %w[head torso stomach legs].freeze
      ELEMENTS = %w[normal fire water earth air arcane].freeze

      # Attack type mapping
      ACTION_TYPES = {
        1 => :melee_attack,
        2 => :targeted_attack,
        3 => :instant_magic,
        4 => :potion_item,
        5 => :targeted_ally_spell,
        6 => :text_action,
        7 => :area_effect
      }.freeze

      attr_reader :battle, :config, :errors

      def initialize(battle)
        @battle = battle
        @config = load_combat_config
        @errors = []
      end

      # Submit a turn for a participant
      # @param character [Character] the acting character
      # @param attacks [Array] array of attack selections {body_part:, action_key:, mana:}
      # @param blocks [Array] array of block selections {body_part:, action_key:}
      # @param skills [Array] array of skill/magic to use
      def submit_turn(character, attacks: [], blocks: [], skills: [])
        participant = find_participant(character)
        return failure("Not a participant in this battle") unless participant
        return failure("Not your turn") unless can_act?(participant)
        return failure("You are defeated") unless participant.is_alive

        # Validate action point budget
        total_cost = calculate_total_cost(attacks, blocks, skills)
        return failure("Exceeds action point limit (#{total_cost}/#{action_points_limit})") if total_cost > action_points_limit

        # Validate mana usage
        total_mana = calculate_mana_cost(skills)
        return failure("Exceeds mana limit") if total_mana > mana_limit
        return failure("Not enough MP") if total_mana > participant.current_mp

        # Store pending actions
        store_pending_actions(participant, attacks, blocks, skills)

        # Check if all participants have submitted
        if all_participants_ready?
          resolve_round!
        else
          Result.new(
            success: true,
            battle: battle.reload,
            log_entries: [],
            message: "Turn submitted. Waiting for opponent.",
            round_complete: false
          )
        end
      end

      # Resolve the round when all participants have acted
      def resolve_round!
        log_entries = []

        # Get active participants by team
        team_alpha = battle.battle_participants.where(team: "alpha", is_alive: true)
        team_beta = battle.battle_participants.where(team: "beta", is_alive: true)

        # Process skills first (buffs, heals, etc.)
        log_entries += process_skills(team_alpha + team_beta)

        # Process attacks and blocks simultaneously
        log_entries += process_combat(team_alpha, team_beta)

        # Apply DOT effects, regeneration, etc.
        log_entries += process_end_of_round

        # Clear pending actions
        clear_pending_actions

        # Advance round
        battle.update!(round_number: battle.round_number + 1)

        # Check for battle end
        check_battle_end!

        Result.new(
          success: true,
          battle: battle.reload,
          log_entries: log_entries,
          message: battle.completed? ? "Battle ended!" : "Round #{battle.round_number - 1} complete!",
          round_complete: true
        )
      end

      # Calculate combat statistics for a participant
      def combat_stats(participant)
        {
          hp: participant.current_hp,
          max_hp: participant.max_hp,
          mp: participant.current_mp,
          max_mp: participant.max_mp,
          fatigue: participant.fatigue,
          body_damage: participant.body_damage,
          damage_dealt: participant.damage_dealt,
          damage_received: participant.damage_received,
          hits_landed: participant.hits_landed,
          hits_blocked: participant.hits_blocked
        }
      end

      # Get available actions for a participant
      def available_actions(participant)
        actions = {
          attacks: [],
          blocks: [],
          skills: []
        }

        # Basic attacks for each body part
        BODY_PARTS.each do |part|
          actions[:attacks] << {
            key: "#{part}_strike",
            name: "Strike #{part.titleize}",
            body_part: part,
            cost: body_part_config(part)["block_difficulty"],
            type: :targeted
          }
        end

        # Add combo attacks
        config["attack_types"]&.each do |key, attack|
          next unless attack["type"] == 2

          actions[:attacks] << {
            key: key,
            name: attack["name"],
            body_parts: attack["body_parts"] || [attack["body_part"]],
            cost: attack["action_cost"],
            type: :combo
          }
        end

        # Blocks
        BODY_PARTS.each do |part|
          actions[:blocks] << {
            key: "block_#{part}",
            name: "Block #{part.titleize}",
            body_part: part,
            cost: body_part_config(part)["block_difficulty"]
          }
        end

        # Skills from character
        if participant.character
          Game::Combat::SkillExecutor.available_skills(participant.character).each do |skill|
            actions[:skills] << skill.merge(
              cost: config.dig("magic_types", skill[:id])&.dig("action_cost") || 50,
              mana: skill[:cost][:mp] || skill[:cost]["mp"] || 0
            )
          end
        end

        # Add magic from config
        config["magic_types"]&.each do |key, magic|
          actions[:skills] << {
            key: key,
            name: magic["name"],
            cost: magic["action_cost"],
            mana: magic["mana_cost"],
            element: magic["element"],
            effect: magic["effect"],
            type: ACTION_TYPES[magic["type"]]
          }
        end

        actions
      end

      private

      def load_combat_config
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        if File.exist?(config_path)
          YAML.load_file(config_path)
        else
          default_config
        end
      end

      def default_config
        {
          "defaults" => {
            "action_points_per_turn" => 80,
            "max_mana_per_attack" => 50
          },
          "attack_penalties" => [
            {"attacks" => 0, "penalty" => 0},
            {"attacks" => 1, "penalty" => 0},
            {"attacks" => 2, "penalty" => 25},
            {"attacks" => 3, "penalty" => 75}
          ]
        }
      end

      def body_part_config(part)
        config.dig("body_parts", part) || {"damage_multiplier" => 1.0, "block_difficulty" => 30}
      end

      def action_points_limit
        battle.action_points_per_turn || config.dig("defaults", "action_points_per_turn") || 80
      end

      def mana_limit
        battle.max_mana_per_turn || config.dig("defaults", "max_mana_per_attack") || 50
      end

      def find_participant(character)
        battle.battle_participants.find_by(character: character)
      end

      def can_act?(participant)
        # In simultaneous turn mode, everyone can act
        return true if battle.combat_mode == "simultaneous"

        # Otherwise check if it's their turn
        battle.current_turn_character_id == participant.character_id
      end

      def calculate_total_cost(attacks, blocks, skills)
        attack_cost = attacks.sum { |a| action_cost(a[:action_key] || a["action_key"]) }
        block_cost = blocks.sum { |b| action_cost(b[:action_key] || b["action_key"]) }
        skill_cost = skills.sum { |s| action_cost(s[:key] || s["key"]) }

        # Add penalty for multiple attacks
        penalty = attack_penalty(attacks.size)

        attack_cost + block_cost + skill_cost + penalty
      end

      def calculate_mana_cost(skills)
        skills.sum { |s| mana_cost(s[:key] || s["key"]) }
      end

      def action_cost(action_key)
        return 0 unless action_key

        config.dig("attack_types", action_key, "action_cost") ||
          config.dig("block_types", action_key, "action_cost") ||
          config.dig("magic_types", action_key, "action_cost") ||
          0
      end

      def mana_cost(action_key)
        return 0 unless action_key

        config.dig("magic_types", action_key, "mana_cost") || 0
      end

      def attack_penalty(attack_count)
        penalties = config["attack_penalties"] || []
        penalty_entry = penalties.find { |p| p["attacks"] == attack_count }
        penalty_entry&.dig("penalty") || 0
      end

      def store_pending_actions(participant, attacks, blocks, skills)
        participant.update!(
          pending_attacks: attacks,
          pending_blocks: blocks,
          pending_skills: skills,
          action_points_used: calculate_total_cost(attacks, blocks, skills)
        )
      end

      def all_participants_ready?
        battle.battle_participants.where(is_alive: true).all? do |p|
          p.pending_attacks.present? || p.pending_blocks.present? || p.pending_skills.present? ||
            p.participant_type == "npc"
        end
      end

      def process_skills(participants)
        log_entries = []

        participants.each do |participant|
          next unless participant.pending_skills.present?

          participant.pending_skills.each do |skill|
            result = execute_skill(participant, skill)
            log_entries << create_log_entry(:skill, participant, result)
          end
        end

        log_entries
      end

      def process_combat(team_alpha, team_beta)
        log_entries = []

        # Each attacker attacks defenders
        team_alpha.each do |attacker|
          next unless attacker.pending_attacks.present?

          defender = select_target(team_beta)
          next unless defender

          attacker.pending_attacks.each do |attack|
            result = resolve_attack(attacker, defender, attack)
            log_entries << create_log_entry(:attack, attacker, result)
          end
        end

        team_beta.each do |attacker|
          next unless attacker.pending_attacks.present?

          defender = select_target(team_alpha)
          next unless defender

          attacker.pending_attacks.each do |attack|
            result = resolve_attack(attacker, defender, attack)
            log_entries << create_log_entry(:attack, attacker, result)
          end
        end

        log_entries
      end

      def select_target(team)
        # Select a random alive target
        team.where(is_alive: true).sample
      end

      def resolve_attack(attacker, defender, attack)
        body_part = attack[:body_part] || attack["body_part"] || BODY_PARTS.sample
        action_key = attack[:action_key] || attack["action_key"]

        # Check if defender is blocking this body part
        blocked = defender.pending_blocks&.any? do |block|
          block[:body_part] == body_part || block["body_part"] == body_part
        end

        # Calculate damage
        base_damage = calculate_base_damage(attacker)
        multiplier = body_part_config(body_part)["damage_multiplier"] || 1.0
        damage = (base_damage * multiplier).round

        # Apply critical hit
        critical = rand(100) < (config.dig("defaults", "critical_hit_chance") || 10)
        damage = (damage * 1.5).round if critical

        # Check hit/block
        hit_chance = config.dig("defaults", "base_hit_chance") || 85
        block_chance = blocked ? (config.dig("defaults", "base_block_chance") || 50) : 0

        hit_roll = rand(100)
        blocked_hit = hit_roll < block_chance

        if blocked_hit
          # Blocked - reduced or no damage
          damage = (damage * 0.2).round
          defender.increment!(:hits_blocked)
          result_type = :blocked
        elsif hit_roll < hit_chance
          # Hit - full damage
          apply_damage(defender, damage, body_part)
          attacker.increment!(:hits_landed)
          update_damage_stats(attacker, defender, damage, "normal")
          result_type = critical ? :critical : :hit
        else
          # Miss
          damage = 0
          result_type = :miss
        end

        {
          attacker: attacker.combatant_name,
          defender: defender.combatant_name,
          body_part: body_part,
          damage: damage,
          result: result_type,
          critical: critical,
          action: action_key
        }
      end

      def calculate_base_damage(participant)
        if participant.character
          stats = participant.character.stats
          strength = stats.respond_to?(:strength) ? stats.strength : 10
          (strength * 2) + rand(1..10)
        else
          # NPC damage
          npc = participant.npc_template
          npc&.damage_range&.to_a&.sample || rand(10..20)
        end
      end

      def apply_damage(participant, damage, body_part)
        # Update HP
        new_hp = [participant.current_hp - damage, 0].max
        participant.update!(current_hp: new_hp)

        # Track body part damage
        body_damage = participant.body_damage || {}
        body_damage[body_part] = (body_damage[body_part] || 0) + damage
        participant.update!(body_damage: body_damage)

        # Check if defeated
        if new_hp <= 0
          participant.update!(is_alive: false)
        end
      end

      def update_damage_stats(attacker, defender, damage, element)
        # Attacker dealt damage
        dealt = attacker.damage_dealt || {}
        dealt[element] = (dealt[element] || 0) + damage
        dealt["total"] = (dealt["total"] || 0) + damage
        attacker.update!(damage_dealt: dealt)

        # Defender received damage
        received = defender.damage_received || {}
        received[element] = (received[element] || 0) + damage
        received["total"] = (received["total"] || 0) + damage
        defender.update!(damage_received: received)
      end

      def execute_skill(participant, skill)
        skill_key = skill[:key] || skill["key"]
        magic_config = config.dig("magic_types", skill_key) || {}

        # Deduct mana
        mana = magic_config["mana_cost"] || 0
        if mana > 0 && participant.current_mp >= mana
          participant.update!(current_mp: participant.current_mp - mana)
        end

        case magic_config["effect"]
        when "heal_hp", "heal"
          amount = magic_config["amount"] || 30
          new_hp = [participant.current_hp + amount, participant.max_hp].min
          participant.update!(current_hp: new_hp)
          {skill: skill_key, effect: "healed", amount: amount}
        when "heal_mp"
          amount = magic_config["amount"] || 20
          new_mp = [participant.current_mp + amount, participant.max_mp].min
          participant.update!(current_mp: new_mp)
          {skill: skill_key, effect: "restored_mp", amount: amount}
        when "shield", "barrier"
          # Add buff
          buffs = participant.combat_buffs || []
          buffs << {type: "shield", duration: 2, amount: 50}
          participant.update!(combat_buffs: buffs)
          {skill: skill_key, effect: "shield_applied"}
        else
          # Damage spell
          damage = magic_config["damage"] || 0
          element = magic_config["element"] || "arcane"
          {skill: skill_key, effect: "damage", amount: damage, element: element}
        end
      end

      def process_end_of_round
        log_entries = []

        battle.battle_participants.where(is_alive: true).each do |participant|
          # Process DOT effects
          buffs = participant.combat_buffs || []
          buffs.each do |buff|
            if buff["type"] == "dot"
              damage = buff["damage"] || 5
              apply_damage(participant, damage, "torso")
              log_entries << create_log_entry(:dot, participant, {damage: damage, source: buff["source"]})
            end
          end

          # Tick down buff durations
          buffs = buffs.map do |buff|
            buff["duration"] = (buff["duration"] || 1) - 1
            buff
          end.select { |b| b["duration"] > 0 }
          participant.update!(combat_buffs: buffs)

          # Natural MP regeneration
          regen = (participant.max_mp * 0.05).round
          new_mp = [participant.current_mp + regen, participant.max_mp].min
          participant.update!(current_mp: new_mp) if regen > 0

          # Reduce fatigue
          fatigue = participant.fatigue - 0.5
          participant.update!(fatigue: [fatigue, 0].max)
        end

        log_entries
      end

      def clear_pending_actions
        battle.battle_participants.update_all(
          pending_attacks: [],
          pending_blocks: [],
          pending_skills: [],
          action_points_used: 0
        )
      end

      def check_battle_end!
        team_alpha_alive = battle.battle_participants.where(team: "alpha", is_alive: true).exists?
        team_beta_alive = battle.battle_participants.where(team: "beta", is_alive: true).exists?

        if !team_alpha_alive || !team_beta_alive
          winner_team = team_alpha_alive ? "alpha" : "beta"
          battle.update!(status: :completed, ended_at: Time.current)

          # Award rewards
          distribute_rewards(winner_team)
        end
      end

      def distribute_rewards(winner_team)
        battle.battle_participants.where(team: winner_team, is_alive: true).each do |winner|
          next unless winner.character

          # Calculate XP based on battle
          xp = calculate_xp_reward(winner)
          gold = calculate_gold_reward(winner)

          winner.character.increment!(:experience, xp)
          winner.character.increment!(:gold, gold)
        end
      end

      def calculate_xp_reward(winner)
        base_xp = 50
        rounds_bonus = battle.round_number * 10
        damage_bonus = (winner.damage_dealt&.dig("total") || 0) / 10

        base_xp + rounds_bonus + damage_bonus
      end

      def calculate_gold_reward(winner)
        10 + rand(1..20)
      end

      def create_log_entry(log_type, participant, data)
        message = format_log_message(log_type, participant, data)

        battle.combat_log_entries.create!(
          round_number: battle.round_number,
          sequence: battle.next_sequence_for(battle.round_number),
          log_type: log_type.to_s,
          message: message,
          actor_id: participant.id,
          payload: data
        )

        {round: battle.round_number, type: log_type, message: message, data: data}
      end

      def format_log_message(log_type, participant, data)
        case log_type
        when :attack
          case data[:result]
          when :critical
            "💥 CRITICAL! #{data[:attacker]} strikes #{data[:defender]}'s #{data[:body_part]} for #{data[:damage]} damage!"
          when :hit
            "⚔️ #{data[:attacker]} hits #{data[:defender]}'s #{data[:body_part]} for #{data[:damage]} damage."
          when :blocked
            "🛡️ #{data[:defender]} blocks #{data[:attacker]}'s attack on #{data[:body_part]}! (#{data[:damage]} reduced damage)"
          when :miss
            "💨 #{data[:attacker]}'s attack on #{data[:defender]}'s #{data[:body_part]} misses!"
          end
        when :skill
          "✨ #{participant.combatant_name} uses «#{data[:skill]}» — #{data[:effect]}#{data[:amount] ? " (#{data[:amount]})" : ""}"
        when :dot
          "🔥 #{participant.combatant_name} takes #{data[:damage]} damage from #{data[:source]}!"
        else
          "#{participant.combatant_name} performs an action"
        end
      end

      def failure(message)
        @errors << message
        Result.new(success: false, battle: battle, log_entries: [], message: message, round_complete: false)
      end
    end
  end
end
