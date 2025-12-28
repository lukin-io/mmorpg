# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Handles open-world PVP encounters between players.
    # Uses the same battle system as PvE, adapted for player-vs-player combat.
    #
    # Features:
    # - Concurrency protection via row-level locking
    # - Deterministic combat with persistent RNG seeds
    # - Unified damage formula shared with PvE
    # - VitalsService integration for damage/healing
    # - Locality enforcement (same zone, range checks)
    # - Anti-abuse protections (level gap, repeat kills)
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
    #   # Deterministic mode (for testing):
    #   service = Game::Combat::PvpEncounterService.new(attacker, defender, rng: Random.new(12345))
    #
    class PvpEncounterService
      Result = Struct.new(:success, :battle, :message, :combat_log, :rewards, :metadata, keyword_init: true)

      ACTIONS = %i[attack defend skill flee surrender].freeze

      # Anti-abuse constants
      MAX_KILLS_PER_TARGET_PER_DAY = 3
      NEWBIE_PROTECTION_LEVEL = 10
      MAX_LEVEL_DIFFERENCE = 20
      ATTACK_RANGE = 5 # Tiles

      attr_reader :attacker, :defender, :battle, :zone, :errors, :rng, :damage_formula

      def initialize(attacker, defender, zone: nil, rng: nil)
        @attacker = attacker
        @defender = defender
        @zone = zone || attacker.position&.zone
        @rng = rng
        @errors = []
        @damage_formula = nil
      end

      # Start a new PVP encounter
      # Uses row-level locking to prevent duplicate battles
      #
      # @return [Result]
      def start_encounter!
        # Acquire locks on both characters to prevent race conditions
        # Order by ID to prevent deadlocks
        locked_characters = Character.where(id: [attacker.id, defender.id])
          .order(:id)
          .lock("FOR UPDATE")
          .to_a

        # Re-fetch to ensure we have latest state
        @attacker = locked_characters.find { |c| c.id == attacker.id }
        @defender = locked_characters.find { |c| c.id == defender.id }

        # Validation checks
        return failure("Already in combat") if either_in_combat?
        return failure("Cannot attack dead character") if attacker.current_hp <= 0
        return failure("Target is dead") if defender.current_hp <= 0

        # Locality checks
        locality_check = check_locality
        return failure(locality_check[:reason]) unless locality_check[:allowed]

        # Anti-abuse checks
        abuse_check = check_anti_abuse
        return failure(abuse_check[:reason]) unless abuse_check[:allowed]

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
      rescue ActiveRecord::RecordNotUnique
        failure("Already in combat")
      end

      # Process a combat action from a character
      #
      # @param character [Character] the character performing the action
      # @param action_type [Symbol] :attack, :defend, :skill, :flee, or :surrender
      # @param params [Hash] additional action parameters
      # @return [Result]
      def process_action!(action_type:, character: nil, **params)
        character ||= attacker
        @battle ||= find_active_battle(character)
        return failure("Not in combat") unless battle

        # Initialize RNG from battle seed
        initialize_rng_from_battle!

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

        # Initialize RNG from battle seed
        initialize_rng_from_battle!

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

        # Process attacks using unified damage formula
        attacks.each do |attack|
          body_part = attack["body_part"] || attack[:body_part]
          action_key = attack["action_key"] || attack[:action_key]
          next if action_key.blank?

          # Calculate damage using unified formula
          is_defending = opponent_participant&.is_defending
          is_critical = damage_formula.critical_hit?(character)
          multiplier = (action_key == "aimed") ? 1.3 : 1.0

          damage = damage_formula.call(
            character,
            opponent,
            is_defending: is_defending,
            is_critical: is_critical,
            damage_multiplier: multiplier
          )

          total_damage += damage
          attack_name = (action_key == "aimed") ? "aimed attack" : "attack"
          combat_log << "#{character.name} #{attack_name}s #{opponent.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if is_critical}."
        end

        # Apply damage through VitalsService
        if total_damage > 0
          apply_damage_via_vitals!(opponent, opponent_participant, total_damage, "PVP: #{character.name}")

          # Check if opponent defeated
          if opponent_participant.reload.current_hp <= 0
            return complete_battle!(winner: character, loser: opponent, combat_log: combat_log)
          end
        end

        # Process opponent's turn (counterattack)
        body_parts = %w[head torso stomach legs]
        opponent_target = body_parts[rng.rand(body_parts.size)]
        blocked = blocks_set.include?(opponent_target)

        opponent_damage = damage_formula.call(
          opponent,
          character,
          is_defending: blocked,
          is_critical: damage_formula.critical_hit?(opponent)
        )
        combat_log << "#{opponent.name} attacks #{character.name}'s #{opponent_target} for #{opponent_damage} damage#{" (blocked!)" if blocked}."

        # Apply damage through VitalsService
        apply_damage_via_vitals!(character, participant, opponent_damage, "PVP: #{opponent.name}")

        # Check if character defeated
        if participant.reload.current_hp <= 0
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

      # ==================
      # Locality Checks
      # ==================

      def check_locality
        # No zone = unsafe wilderness, allow PVP
        return {allowed: true} if zone.nil?

        # Check same zone
        unless same_zone?
          return {allowed: false, reason: "Target is not in the same zone"}
        end

        # Check range (if positions available)
        unless within_attack_range?
          return {allowed: false, reason: "Target is out of range"}
        end

        # Check safe building
        if in_safe_building?(defender)
          return {allowed: false, reason: "Target is in a safe building"}
        end

        {allowed: true}
      end

      def same_zone?
        return true if zone.nil?

        attacker_zone = get_character_zone(attacker)
        defender_zone = get_character_zone(defender)

        attacker_zone&.id == defender_zone&.id
      end

      def get_character_zone(character)
        # Get zone from position (the standard way)
        return character.position.zone if character.respond_to?(:position) && character.position&.zone

        # No position means no zone context
        nil
      end

      def within_attack_range?
        return true unless attacker.respond_to?(:position) && defender.respond_to?(:position)
        return true if attacker.position.nil? || defender.position.nil?

        distance = calculate_distance(
          attacker.position.x, attacker.position.y,
          defender.position.x, defender.position.y
        )

        distance <= ATTACK_RANGE
      end

      def calculate_distance(x1, y1, x2, y2)
        Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
      end

      def in_safe_building?(character)
        return false unless character.respond_to?(:position)
        return false if character.position.nil?

        # Check if position is in a safe building (shop, bank, etc.)
        position = character.position
        return false unless position.respond_to?(:building)

        safe_building_types = %w[shop bank temple hospital inn]
        safe_building_types.include?(position.building&.building_type)
      end

      # ==================
      # Anti-Abuse Checks
      # ==================

      def check_anti_abuse
        # Newbie protection
        if defender.level < NEWBIE_PROTECTION_LEVEL && attacker.level >= NEWBIE_PROTECTION_LEVEL
          return {allowed: false, reason: "Cannot attack players below level #{NEWBIE_PROTECTION_LEVEL}"}
        end

        # Level difference cap
        level_diff = (attacker.level - defender.level).abs
        if level_diff > MAX_LEVEL_DIFFERENCE
          return {allowed: false, reason: "Level difference too large (max #{MAX_LEVEL_DIFFERENCE})"}
        end

        # Check repeat kill farming
        if repeat_kill_farming?
          return {allowed: false, reason: "You have killed this player too many times today"}
        end

        {allowed: true}
      end

      def repeat_kill_farming?
        attacker.metadata ||= {}
        kills_today = attacker.metadata.dig("pvp_kills", defender.id.to_s, Date.current.to_s) || 0
        kills_today >= MAX_KILLS_PER_TARGET_PER_DAY
      end

      def record_kill!(winner, loser)
        winner.metadata ||= {}
        winner.metadata["pvp_kills"] ||= {}
        winner.metadata["pvp_kills"][loser.id.to_s] ||= {}

        today = Date.current.to_s
        current_kills = winner.metadata["pvp_kills"][loser.id.to_s][today] || 0
        winner.metadata["pvp_kills"][loser.id.to_s][today] = current_kills + 1
        winner.save!
      end

      # ==================
      # Combat Helpers
      # ==================

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

      # ==================
      # Battle Creation
      # ==================

      def create_battle!
        # Generate deterministic seed for RNG
        seed = generate_battle_seed
        @rng = Random.new(seed)
        @damage_formula = Game::Formulas::CombatDamageFormula.new(rng: @rng)

        @battle = Battle.create!(
          battle_type: :pvp,
          status: :active,
          zone: zone,
          initiator: attacker,
          turn_number: 1,
          initiative_order: calculate_initiative,
          action_points_per_turn: [attacker.max_action_points, defender.max_action_points].min,
          pvp_mode: "duel",
          rng_seed: seed
        )
      end

      def generate_battle_seed
        # Deterministic seed based on characters and timestamp
        base = "#{attacker.id}-#{defender.id}-#{Time.current.to_i}"
        Digest::MD5.hexdigest(base).to_i(16) % (2**31)
      end

      def initialize_rng_from_battle!
        return if @rng && @damage_formula

        seed = battle.rng_seed || generate_battle_seed
        # Advance RNG based on turn number for consistency
        @rng = Random.new(seed)
        battle.turn_number.times { @rng.rand }
        @damage_formula = Game::Formulas::CombatDamageFormula.new(rng: @rng)
      end

      def create_participants!
        # Attacker (alpha team)
        battle.battle_participants.create!(
          character: attacker,
          team: "alpha",
          role: "combatant",
          initiative: attacker_initiative,
          current_hp: attacker.current_hp,
          max_hp: attacker.max_hp,
          is_alive: true
        )

        # Defender (beta team)
        battle.battle_participants.create!(
          character: defender,
          team: "beta",
          role: "combatant",
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
        @attacker_initiative ||= begin
          base = attacker.agility
          base + rng.rand(1..10)
        end
      end

      def defender_initiative
        @defender_initiative ||= begin
          base = defender.agility
          base + rng.rand(1..10)
        end
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

      # ==================
      # Action Processing
      # ==================

      def process_attack!(character, params)
        participant = battle.battle_participants.find_by(character: character)
        opponent = find_opponent(character)
        opponent_participant = battle.battle_participants.find_by(character: opponent)

        body_part = params[:body_part] || "torso"
        action_key = params[:action_key]
        is_aimed = action_key == "aimed"
        combat_log = []

        # Calculate damage using unified formula
        is_critical = damage_formula.critical_hit?(character)
        multiplier = is_aimed ? 1.3 : 1.0

        damage = damage_formula.call(
          character,
          opponent,
          is_defending: opponent_participant&.is_defending,
          is_critical: is_critical,
          damage_multiplier: multiplier
        )

        # Apply damage through VitalsService
        apply_damage_via_vitals!(opponent, opponent_participant, damage, "PVP: #{character.name}")

        attack_type = is_aimed ? "🎯 aimed attack" : "attacks"
        combat_log << "#{character.name} #{attack_type} #{opponent.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if is_critical}."

        # Check for defeat
        if opponent_participant.reload.current_hp <= 0
          return complete_battle!(winner: character, loser: opponent, combat_log: combat_log)
        end

        # Opponent counterattack
        counter_damage = damage_formula.call(
          opponent,
          character,
          is_defending: participant.is_defending,
          is_critical: damage_formula.critical_hit?(opponent)
        )
        apply_damage_via_vitals!(character, participant, counter_damage, "PVP: #{opponent.name}")

        combat_log << "#{opponent.name} counterattacks for #{counter_damage} damage!"

        if participant.reload.current_hp <= 0
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
        combat_log = ["#{character.name} takes a defensive stance."]

        # Opponent attacks (reduced by defense)
        damage = damage_formula.call(opponent, character, is_defending: true)
        apply_damage_via_vitals!(character, participant, damage, "PVP: #{opponent.name}")

        combat_log << "#{opponent.name} attacks for #{damage} damage (reduced by defense)."

        if participant.reload.current_hp <= 0
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
        counter_damage = damage_formula.call(opponent, character, is_defending: false)
        apply_damage_via_vitals!(character, participant, counter_damage, "PVP: #{opponent.name}")

        combat_log << "#{opponent.name} counterattacks for #{counter_damage} damage!"

        if participant.reload.current_hp <= 0
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

        # Flee chance based on agility comparison using seeded RNG
        char_agility = character.agility
        opp_agility = opponent.agility
        flee_chance = 30 + (char_agility - opp_agility) * 2
        flee_chance = flee_chance.clamp(10, 90)

        combat_log = []

        if rng.rand(100) < flee_chance
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
          damage = damage_formula.call(opponent, character, is_defending: false)
          apply_damage_via_vitals!(character, participant, damage, "PVP: #{opponent.name}")

          combat_log << "#{opponent.name} attacks #{character.name} for #{damage} damage as they try to escape!"

          if participant.reload.current_hp <= 0
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

      # ==================
      # Damage Application (VitalsService Integration)
      # ==================

      def apply_damage_via_vitals!(character, participant, damage, source)
        # Update battle participant
        new_hp = [participant.current_hp - damage, 0].max
        participant.update!(current_hp: new_hp, is_defending: false)

        # Apply through VitalsService for proper side effects
        # (in_combat flag, last_combat_at, death handling, broadcasts)
        vitals_service = Characters::VitalsService.new(character)
        vitals_service.apply_damage(damage, source: source)
      end

      # ==================
      # Battle Completion
      # ==================

      def complete_battle!(winner:, loser:, combat_log:)
        battle.update!(status: :completed, ended_at: Time.current)

        # Update participants - only the winner remains alive
        battle.battle_participants.each do |participant|
          is_winner = participant.character_id == winner.id
          participant.update!(is_alive: is_winner, current_hp: is_winner ? participant.current_hp : 0)
        end

        # Set loser's character HP to 0
        # Note: VitalsService handles death (in_combat flag, death handler) during damage application
        # For surrender, we just set HP to 0 directly
        loser.update!(current_hp: 0)
        loser.reload

        # Record kill for anti-abuse tracking
        record_kill!(winner, loser)

        # Grant rewards (with diminishing returns)
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

        # Check diminishing returns
        kills_today = winner.metadata.dig("pvp_kills", loser.id.to_s, Date.current.to_s) || 0

        # Diminishing returns: 100% first kill, 50% second, 25% third, 0% after
        reward_multiplier = case kills_today
        when 0 then 1.0
        when 1 then 0.5
        when 2 then 0.25
        else 0.0
        end

        return {xp: 0, gold: 0, honor: 0, message: "No rewards (farmed)"} if reward_multiplier.zero?

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
        xp = (base_xp * xp_multiplier * reward_multiplier).round

        # Small gold reward
        gold = (rng.rand(10..30) * reward_multiplier).round

        # Honor/ranking points
        honor = ((10 + level_diff.clamp(-5, 10)) * reward_multiplier).round

        # Apply rewards
        winner.gain_experience!(xp, source: "PVP victory over #{loser.name}") if winner.respond_to?(:gain_experience!)
        winner.add_currency!(:gold, gold, source: "PVP victory") if winner.respond_to?(:add_currency!)

        {xp: xp, gold: gold, honor: honor}
      rescue => e
        Rails.logger.error("Failed to grant PVP rewards: #{e.message}")
        {}
      end

      # ==================
      # AP Calculation
      # ==================

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

      # ==================
      # Combat Logging
      # ==================

      def persist_log_entry!(message)
        battle.combat_log_entries.create!(
          round_number: battle.turn_number,
          sequence: next_log_sequence,
          log_type: log_type_from_message(message),
          message: message,
          damage_amount: extract_damage(message)
        )
      rescue => e
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

      # ==================
      # Broadcasting
      # ==================

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
        current_turn = battle.turn_number

        ActionCable.server.broadcast(
          "battle:#{battle.id}",
          {
            type: "round_complete",
            battle_id: battle.id,
            turn: current_turn,
            log_entries: combat_log.map { |msg| {message: msg, type: log_type_from_message(msg), turn: current_turn} },
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
