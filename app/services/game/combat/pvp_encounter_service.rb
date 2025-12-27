# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Handles open-world PVP encounters between players.
    # Uses the same battle system as PvE, adapted for player-vs-player combat.
    #
    # Inputs:
    #   - attacker: Character initiating the attack
    #   - defender: Character being attacked
    #   - zone: Optional zone where combat occurs
    #
    # Returns:
    #   Result with battle state, logs, and rewards
    #
    # Usage:
    #   service = Game::Combat::PvpEncounterService.new(attacker, defender)
    #   result = service.start_encounter!
    #   result = service.process_action!(action_type: :attack)
    #
    class PvpEncounterService
      Result = Struct.new(:success, :battle, :message, :combat_log, :rewards, :metadata, keyword_init: true)

      ACTIONS = %i[attack defend skill flee surrender].freeze

      attr_reader :attacker, :defender, :battle, :zone, :errors

      def initialize(attacker, defender, zone: nil)
        @attacker = attacker
        @defender = defender
        @zone = zone || attacker.position&.zone
        @errors = []
      end

      # Start a new PVP encounter
      #
      # @return [Result]
      def start_encounter!
        return failure("Already in combat") if either_in_combat?
        return failure("Cannot attack dead character") if attacker.current_hp <= 0
        return failure("Target is dead") if defender.current_hp <= 0

        # Check PVP rules
        pvp_check = Game::Pvp::ZoneRules.check_pvp_allowed(zone, attacker, defender)
        return failure(pvp_check[:reason]) unless pvp_check[:allowed]

        ActiveRecord::Base.transaction do
          create_battle!
          create_participants!
          flag_attacker_for_pvp!
          record_attack_for_revenge!
          broadcast_combat_started!
        end

        combat_log = ["#{attacker.name} attacks #{defender.name}!"]
        persist_log_entry!(combat_log.first)

        Result.new(
          success: true,
          battle: battle,
          message: "PVP combat started with #{defender.name}!",
          combat_log: combat_log
        )
      rescue ActiveRecord::RecordInvalid => e
        failure("Failed to start encounter: #{e.message}")
      end

      # Process a combat action from a character
      #
      # @param character [Character] the character performing the action
      # @param action_type [Symbol] :attack, :defend, :skill, :flee, or :surrender
      # @param params [Hash] additional action parameters
      # @return [Result]
      def process_action!(character: nil, action_type:, **params)
        character ||= attacker
        @battle ||= find_active_battle(character)
        return failure("Not in combat") unless battle

        # Ensure we have both participants
        @attacker ||= find_alpha_character
        @defender ||= find_beta_character

        participant = battle.battle_participants.find_by(character: character)
        return failure("Character not in this combat") unless participant
        return failure("Character is dead") unless participant.is_alive

        case action_type.to_sym
        when :attack
          process_attack!(character, params)
        when :defend
          process_defend!(character)
        when :skill
          process_skill!(character, params[:skill_id])
        when :flee
          process_flee!(character)
        when :surrender
          process_surrender!(character)
        else
          failure("Unknown action: #{action_type}")
        end
      end

      # Process a full turn with attacks, blocks, and skills (turn-based mode)
      #
      # @param character [Character] the acting character
      # @param attacks [Array] attack actions
      # @param blocks [Array] block actions
      # @param skills [Array] skill actions
      # @return [Result]
      def process_turn!(character:, attacks: [], blocks: [], skills: [])
        @battle ||= find_active_battle(character)
        return failure("Not in combat") unless battle

        participant = battle.battle_participants.find_by(character: character)
        return failure("Character not in this combat") unless participant
        return failure("Character is dead") unless participant.is_alive

        # Validate action points
        total_ap = calculate_turn_ap_cost(attacks, blocks, skills)
        max_ap = battle.action_points_per_turn || character.max_action_points
        return failure("Exceeds action points (#{total_ap}/#{max_ap})") if total_ap > max_ap

        opponent = find_opponent(character)
        opponent_participant = battle.battle_participants.find_by(character: opponent)

        combat_log = []
        total_damage = 0

        # Process blocks
        blocks_set = blocks.map { |b| b["body_part"] || b[:body_part] }.compact
        participant.update!(is_defending: blocks_set.any?)

        if blocks_set.any?
          combat_log << "#{character.name} defends their #{blocks_set.join(", ")}."
        end

        # Process attacks
        attacks.each do |attack|
          body_part = attack["body_part"] || attack[:body_part]
          action_key = attack["action_key"] || attack[:action_key]
          next if action_key.blank?

          # Calculate damage
          damage = calculate_pvp_damage(character, opponent, is_defending: opponent_participant&.is_defending)
          damage = (damage * 1.3).to_i if action_key == "aimed"

          # Check for crit
          is_crit = rand(100) < crit_chance(character)
          damage = (damage * 1.5).to_i if is_crit

          total_damage += damage
          attack_name = (action_key == "aimed") ? "aimed attack" : "attack"
          combat_log << "#{character.name} #{attack_name}s #{opponent.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if is_crit}."
        end

        # Apply damage to opponent
        if total_damage > 0
          new_hp = [opponent_participant.current_hp - total_damage, 0].max
          opponent_participant.update!(current_hp: new_hp, is_defending: false)

          # Sync to character
          opponent.update!(current_hp: new_hp)

          # Check if opponent defeated
          if new_hp <= 0
            return complete_battle!(winner: character, loser: opponent, combat_log: combat_log)
          end
        end

        # Process opponent's turn (simple AI-like behavior for now - they attack back)
        # In real PVP, both players submit turns simultaneously
        # For now, opponent gets an auto-response
        opponent_target = %w[head torso stomach legs].sample
        blocked = blocks_set.include?(opponent_target)

        opponent_damage = calculate_pvp_damage(opponent, character, is_defending: blocked)
        combat_log << "#{opponent.name} attacks #{character.name}'s #{opponent_target} for #{opponent_damage} damage#{" (blocked!)" if blocked}."

        # Apply damage to character
        new_hp = [participant.current_hp - opponent_damage, 0].max
        participant.update!(current_hp: new_hp, is_defending: false)
        character.update!(current_hp: new_hp)

        # Check if character defeated
        if new_hp <= 0
          return complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
        end

        # Advance turn
        battle.update!(turn_number: battle.turn_number + 1)

        # Persist and broadcast
        combat_log.each { |msg| persist_log_entry!(msg) }
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Turn #{battle.turn_number} completed",
          combat_log: combat_log
        )
      end

      # Check if combat has ended and handle completion
      def check_combat_end!
        return unless battle

        alpha_participant = battle.battle_participants.find_by(team: "alpha")
        beta_participant = battle.battle_participants.find_by(team: "beta")

        return if alpha_participant.is_alive && beta_participant.is_alive

        if !alpha_participant.is_alive
          winner = beta_participant.character
          loser = alpha_participant.character
        else
          winner = alpha_participant.character
          loser = beta_participant.character
        end

        complete_battle!(winner: winner, loser: loser, combat_log: ["Combat has ended."])
      end

      private

      def either_in_combat?
        attacker_in_combat? || defender_in_combat?
      end

      def attacker_in_combat?
        attacker.battle_participants.joins(:battle).where(battles: {status: :active}).exists?
      end

      def defender_in_combat?
        defender.battle_participants.joins(:battle).where(battles: {status: :active}).exists?
      end

      def find_active_battle(character)
        character.battle_participants.joins(:battle).find_by(battles: {status: :active})&.battle
      end

      def find_alpha_character
        battle.battle_participants.find_by(team: "alpha")&.character
      end

      def find_beta_character
        battle.battle_participants.find_by(team: "beta")&.character
      end

      def find_opponent(character)
        participant = battle.battle_participants.find_by(character: character)
        opponent_team = (participant.team == "alpha") ? "beta" : "alpha"
        battle.battle_participants.find_by(team: opponent_team)&.character
      end

      def create_battle!
        @battle = Battle.create!(
          battle_type: :pvp,
          status: :active,
          zone: zone,
          initiator: attacker,
          turn_number: 1,
          initiative_order: calculate_initiative,
          action_points_per_turn: [attacker.max_action_points, defender.max_action_points].min,
          pvp_mode: "duel"
        )
      end

      def create_participants!
        # Attacker (alpha team)
        battle.battle_participants.create!(
          character: attacker,
          team: "alpha",
          initiative: attacker_initiative,
          current_hp: attacker.current_hp,
          max_hp: attacker.max_hp,
          is_alive: true
        )

        # Defender (beta team)
        battle.battle_participants.create!(
          character: defender,
          team: "beta",
          initiative: defender_initiative,
          current_hp: defender.current_hp,
          max_hp: defender.max_hp,
          is_alive: true
        )
      end

      def calculate_initiative
        if attacker_initiative >= defender_initiative
          %w[alpha beta]
        else
          %w[beta alpha]
        end
      end

      def attacker_initiative
        base = attacker.respond_to?(:agility) ? attacker.agility : 10
        base + rand(1..10)
      end

      def defender_initiative
        base = defender.respond_to?(:agility) ? defender.agility : 10
        base + rand(1..10)
      end

      def flag_attacker_for_pvp!
        flag_service = Game::Pvp::FlagService.new(attacker)
        flag_service.flag_for_hostile_action!(defender)
      end

      def record_attack_for_revenge!
        return unless defender.respond_to?(:metadata)

        defender.metadata ||= {}
        defender.metadata["last_attacked_by_at"] ||= {}
        defender.metadata["last_attacked_by_at"][attacker.id.to_s] = Time.current.iso8601
        defender.save!
      end

      def process_attack!(character, params)
        participant = battle.battle_participants.find_by(character: character)
        opponent = find_opponent(character)
        opponent_participant = battle.battle_participants.find_by(character: opponent)

        body_part = params[:body_part] || "torso"
        combat_log = []

        # Calculate and apply damage
        damage = calculate_pvp_damage(character, opponent, is_defending: opponent_participant&.is_defending)

        # Check for crit
        is_crit = rand(100) < crit_chance(character)
        damage = (damage * 1.5).to_i if is_crit

        new_hp = [opponent_participant.current_hp - damage, 0].max
        opponent_participant.update!(current_hp: new_hp, is_defending: false)
        opponent.update!(current_hp: new_hp)

        combat_log << "#{character.name} attacks #{opponent.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if is_crit}."

        # Check for defeat
        if new_hp <= 0
          return complete_battle!(winner: character, loser: opponent, combat_log: combat_log)
        end

        # Opponent counterattack
        counter_damage = calculate_pvp_damage(opponent, character, is_defending: participant.is_defending)
        new_char_hp = [participant.current_hp - counter_damage, 0].max
        participant.update!(current_hp: new_char_hp, is_defending: false)
        character.update!(current_hp: new_char_hp)

        combat_log << "#{opponent.name} counterattacks for #{counter_damage} damage!"

        if new_char_hp <= 0
          return complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
        end

        # Advance turn
        battle.update!(turn_number: battle.turn_number + 1)
        combat_log.each { |msg| persist_log_entry!(msg) }
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Combat continues",
          combat_log: combat_log
        )
      end

      def process_defend!(character)
        participant = battle.battle_participants.find_by(character: character)
        participant.update!(is_defending: true)

        opponent = find_opponent(character)
        opponent_participant = battle.battle_participants.find_by(character: opponent)

        combat_log = ["#{character.name} takes a defensive stance."]

        # Opponent attacks (reduced by defense)
        damage = calculate_pvp_damage(opponent, character, is_defending: true)
        new_hp = [participant.current_hp - damage, 0].max
        participant.update!(current_hp: new_hp)
        character.update!(current_hp: new_hp)

        combat_log << "#{opponent.name} attacks for #{damage} damage (reduced by defense)."

        if new_hp <= 0
          return complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
        end

        battle.update!(turn_number: battle.turn_number + 1)
        combat_log.each { |msg| persist_log_entry!(msg) }
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: "Defending",
          combat_log: combat_log
        )
      end

      def process_skill!(character, skill_id)
        return failure("No skill specified") unless skill_id

        skill = find_skill(character, skill_id)
        return failure("Skill not found or not unlocked") unless skill

        opponent = find_opponent(character)
        opponent_participant = battle.battle_participants.find_by(character: opponent)

        # Execute skill
        executor = Game::Combat::SkillExecutor.new(
          caster: character,
          target: opponent,
          skill: skill,
          battle: battle
        )

        result = executor.execute!
        return failure(result.message) unless result.success

        combat_log = [result.message]

        # Check if opponent defeated
        opponent_participant.reload
        if opponent_participant.current_hp <= 0
          return complete_battle!(winner: character, loser: opponent, combat_log: combat_log)
        end

        # Opponent counterattack
        participant = battle.battle_participants.find_by(character: character)
        counter_damage = calculate_pvp_damage(opponent, character, is_defending: false)
        new_hp = [participant.current_hp - counter_damage, 0].max
        participant.update!(current_hp: new_hp)
        character.update!(current_hp: new_hp)

        combat_log << "#{opponent.name} counterattacks for #{counter_damage} damage!"

        if new_hp <= 0
          return complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
        end

        battle.update!(turn_number: battle.turn_number + 1)
        combat_log.each { |msg| persist_log_entry!(msg) }
        broadcast_combat_update!(combat_log)

        Result.new(
          success: true,
          battle: battle,
          message: result.message,
          combat_log: combat_log
        )
      end

      def find_skill(character, skill_id)
        skill_id = skill_id.to_s

        if skill_id.start_with?("ability_")
          ability_id = skill_id.sub("ability_", "").to_i
          return character.character_class&.abilities&.find_by(id: ability_id, kind: "active")
        end

        if skill_id.start_with?("skill_")
          node_id = skill_id.sub("skill_", "").to_i
          return character.skill_nodes.where(node_type: "active").find_by(id: node_id)
        end

        character.skill_nodes.where(node_type: "active").find_by(id: skill_id) ||
          character.character_class&.abilities&.find_by(id: skill_id, kind: "active")
      end

      def process_flee!(character)
        opponent = find_opponent(character)

        # Flee chance based on agility comparison
        char_agility = character.respond_to?(:agility) ? character.agility : 10
        opp_agility = opponent.respond_to?(:agility) ? opponent.agility : 10
        flee_chance = 30 + (char_agility - opp_agility) * 2
        flee_chance = flee_chance.clamp(10, 90)

        combat_log = []

        if rand(100) < flee_chance
          battle.update!(status: :completed)
          combat_log << "#{character.name} successfully flees from combat!"
          persist_log_entry!(combat_log.first)
          broadcast_combat_ended!("fled")

          Result.new(
            success: true,
            battle: battle,
            message: "Escaped!",
            combat_log: combat_log,
            metadata: {fled: true}
          )
        else
          combat_log << "#{character.name} failed to flee!"

          # Opponent gets free attack
          participant = battle.battle_participants.find_by(character: character)
          damage = calculate_pvp_damage(opponent, character, is_defending: false)
          new_hp = [participant.current_hp - damage, 0].max
          participant.update!(current_hp: new_hp)
          character.update!(current_hp: new_hp)

          combat_log << "#{opponent.name} attacks #{character.name} for #{damage} damage as they try to escape!"

          if new_hp <= 0
            return complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
          end

          battle.update!(turn_number: battle.turn_number + 1)
          combat_log.each { |msg| persist_log_entry!(msg) }
          broadcast_combat_update!(combat_log)

          Result.new(
            success: false,
            battle: battle,
            message: "Failed to flee",
            combat_log: combat_log,
            metadata: {fled: false}
          )
        end
      end

      def process_surrender!(character)
        opponent = find_opponent(character)

        combat_log = ["#{character.name} surrenders!"]
        persist_log_entry!(combat_log.first)

        complete_battle!(winner: opponent, loser: character, combat_log: combat_log)
      end

      def complete_battle!(winner:, loser:, combat_log:)
        battle.update!(status: :completed, ended_at: Time.current)

        # Update participants - only the winner remains alive
        battle.battle_participants.each do |participant|
          is_winner = participant.character_id == winner.id
          participant.update!(is_alive: is_winner, current_hp: is_winner ? participant.current_hp : 0)
        end

        # Sync loser's character HP to 0
        loser.update!(current_hp: 0)

        # Grant rewards
        rewards = grant_pvp_rewards!(winner, loser)

        outcome = combat_log.any? { |m| m.include?("surrenders") } ? "surrender" : "victory"
        combat_log << "#{winner.name} wins the battle!"
        persist_log_entry!(combat_log.last)

        broadcast_combat_ended!(outcome)

        Result.new(
          success: true,
          battle: battle,
          message: "#{winner.name} wins!",
          combat_log: combat_log,
          rewards: rewards
        )
      end

      def grant_pvp_rewards!(winner, loser)
        return {} unless winner

        # XP based on level difference
        level_diff = loser.level - winner.level
        base_xp = 50 + (loser.level * 5)
        xp_multiplier = if level_diff > 5
          1.5
        elsif level_diff < -5
          0.5
        else
          1.0
        end
        xp = (base_xp * xp_multiplier).round

        # Small gold reward
        gold = rand(10..30)

        # Honor/ranking points
        honor = 10 + level_diff.clamp(-5, 10)

        # Apply rewards
        winner.gain_experience!(xp, source: "PVP victory over #{loser.name}") if winner.respond_to?(:gain_experience!)
        winner.add_currency!(:gold, gold, source: "PVP victory") if winner.respond_to?(:add_currency!)

        {xp: xp, gold: gold, honor: honor}
      rescue StandardError => e
        Rails.logger.error("Failed to grant PVP rewards: #{e.message}")
        {}
      end

      def calculate_pvp_damage(attacker_char, defender_char, is_defending: false)
        base_attack = attacker_char.respond_to?(:attack_power) ? attacker_char.attack_power : 10
        base_defense = defender_char.respond_to?(:defense) ? defender_char.defense : 5

        defense_mult = is_defending ? 1.5 : 1.0
        effective_defense = (base_defense * defense_mult).to_i

        damage = base_attack - (effective_defense / 2)
        damage += rand(1..5)
        [damage, 1].max
      end

      def crit_chance(character)
        base = character.respond_to?(:critical_chance) ? character.critical_chance : 5
        [base, 50].min
      end

      def calculate_turn_ap_cost(attacks, blocks, skills)
        attack_costs = load_action_costs("attack_types")
        block_costs = load_action_costs("block_types")

        attack_total = attacks.sum do |attack|
          key = attack["action_key"] || attack[:action_key]
          attack_costs.dig(key, "action_cost") || 0
        end

        block_total = blocks.sum do |block|
          key = block["action_key"] || block[:action_key]
          block_costs.dig(key, "action_cost") || 30
        end

        skill_total = skills.sum { |skill| skill["cost"] || skill[:cost] || 0 }

        penalty = calculate_multi_attack_penalty(attacks.size)

        attack_total + block_total + skill_total + penalty
      end

      def load_action_costs(category)
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        return {} unless File.exist?(config_path)

        config = YAML.load_file(config_path, permitted_classes: [Symbol])
        config[category] || {}
      end

      def calculate_multi_attack_penalty(attack_count)
        return 0 if attack_count <= 1

        penalties = [0, 0, 25, 75, 150, 250]
        penalties[[attack_count, penalties.size - 1].min]
      end

      def persist_log_entry!(message)
        battle.combat_log_entries.create!(
          round_number: battle.turn_number,
          sequence: next_log_sequence,
          log_type: log_type_from_message(message),
          message: message,
          damage_amount: extract_damage(message)
        )
      rescue StandardError => e
        Rails.logger.error("Failed to persist combat log: #{e.message}")
      end

      def next_log_sequence
        (battle.combat_log_entries.where(round_number: battle.turn_number).maximum(:sequence) || 0) + 1
      end

      def log_type_from_message(message)
        return "attack" if message.include?("attack") || message.include?("damage")
        return "defend" if message.include?("defend") || message.include?("defensive")
        return "flee" if message.include?("flee") || message.include?("escape")
        return "surrender" if message.include?("surrender")
        return "victory" if message.include?("wins")

        "system"
      end

      def extract_damage(message)
        match = message.match(/for (\d+) damage/)
        match ? match[1].to_i : 0
      end

      def broadcast_combat_started!
        [attacker, defender].each do |character|
          opponent = (character == attacker) ? defender : attacker

          ActionCable.server.broadcast(
            "character:#{character.id}:combat",
            {
              type: "pvp_combat_started",
              battle_id: battle.id,
              opponent_name: opponent.name,
              opponent_level: opponent.level,
              opponent_hp: opponent.current_hp,
              opponent_max_hp: opponent.max_hp,
              is_attacker: character == attacker
            }
          )
        end

        ActionCable.server.broadcast(
          "battle:#{battle.id}",
          {
            type: "pvp_started",
            battle_id: battle.id,
            participants: [
              {id: attacker.id, name: attacker.name, hp: attacker.current_hp, max_hp: attacker.max_hp, team: "alpha"},
              {id: defender.id, name: defender.name, hp: defender.current_hp, max_hp: defender.max_hp, team: "beta"}
            ]
          }
        )
      end

      def broadcast_combat_update!(combat_log)
        return unless battle

        alpha = battle.battle_participants.find_by(team: "alpha")
        beta = battle.battle_participants.find_by(team: "beta")

        ActionCable.server.broadcast(
          "battle:#{battle.id}",
          {
            type: "round_complete",
            battle_id: battle.id,
            turn: battle.turn_number,
            log_entries: combat_log.map { |msg| {message: msg, type: log_type_from_message(msg)} },
            participants: [
              {id: alpha.id, current_hp: alpha.current_hp, max_hp: alpha.max_hp},
              {id: beta.id, current_hp: beta.current_hp, max_hp: beta.max_hp}
            ]
          }
        )
      end

      def broadcast_combat_ended!(outcome)
        return unless battle

        winner_participant = battle.battle_participants.find_by(is_alive: true)

        ActionCable.server.broadcast(
          "battle:#{battle.id}",
          {
            type: "pvp_ended",
            battle_id: battle.id,
            outcome: outcome,
            winner_id: winner_participant&.character_id,
            winner_name: winner_participant&.character&.name
          }
        )

        [attacker, defender].compact.each do |character|
          personal_outcome = (character.id == winner_participant&.character_id) ? "victory" : "defeat"

          ActionCable.server.broadcast(
            "character:#{character.id}:combat",
            {
              type: "pvp_combat_ended",
              battle_id: battle.id,
              outcome: personal_outcome
            }
          )
        end
      end

      def failure(message)
        errors << message
        Result.new(success: false, message: message, combat_log: [message])
      end
    end
  end
end
