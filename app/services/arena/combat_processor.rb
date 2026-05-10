# frozen_string_literal: true

module Arena
  # Processes combat actions during an arena match
  # Implements tactical combat mechanics with:
  # - Body part targeting (head, torso, stomach, legs)
  # - Attack types (simple, aimed) with different AP costs
  # - Block types (single and combo coverage)
  # - Standardized combat log messages
  #
  # @example Process an attack action
  #   processor = Arena::CombatProcessor.new(match)
  #   result = processor.process_action(character, :attack, target: other_character)
  #
  class CombatProcessor
    attr_reader :match, :broadcaster

    # Action Points per turn
    AP_PER_TURN = Game::Combat::ActionCatalog::DEFAULT_AP_PER_TURN
    BLOCK_AP_COST = 30
    BODY_PARTS = Game::Combat::ActionCatalog::BODY_PARTS

    # Attack type configurations
    ATTACK_TYPES = {
      simple: {ap_cost: 45, damage_mult: 1.0, hit_bonus: 0, name: "Simple"},
      aimed: {ap_cost: 65, damage_mult: 1.2, hit_bonus: 15, name: "Aimed"}
    }.freeze

    # Body part damage multipliers
    BODY_PART_MULTIPLIERS = {
      "head" => 1.3,
      "torso" => 1.0,
      "stomach" => 1.1,
      "legs" => 0.9
    }.freeze

    # Initialize the combat processor
    #
    # @param match [ArenaMatch] the arena match to process
    def initialize(match)
      @match = match
      @broadcaster = Arena::CombatBroadcaster.new(match)
    end

    # Process a combat action from a character
    #
    # @param character [Character] the character performing the action
    # @param action_type [Symbol] the type of action (:attack, :defend, :skill, :flee)
    # @param params [Hash] additional parameters for the action
    #   - target: Character or ArenaParticipation to target
    #   - attack_type: :simple or :aimed (default :simple)
    #   - body_part: "head", "torso", "stomach", "legs" (default "torso")
    #   - block_parts: Array of body parts to block
    # @return [Result] the result of the action
    def process_action(character, action_type, **params)
      return failure("Match is not active") unless match.live?
      return failure("Character not in this match") unless participant?(character)
      return failure("Character is dead") if character.current_hp <= 0

      # Check AP cost before processing
      ap_cost = calculate_ap_cost(action_type, params)
      current_ap = get_character_ap(character)

      if current_ap < ap_cost
        return failure("Not enough AP (need #{ap_cost}, have #{current_ap})")
      end

      result = case action_type.to_sym
      when :turn
        process_turn(
          character,
          target: params[:target],
          attacks: params[:attacks],
          blocks: params[:blocks],
          skills: params[:skills]
        )
      when :attack
        process_attack(
          character,
          params[:target],
          attack_type: params[:attack_type] || :simple,
          body_part: params[:body_part] || "torso"
        )
      when :defend then process_defend(character, block_parts: params[:block_parts])
      when :skill then process_skill(character, params[:skill_id], params[:target])
      when :flee then process_flee(character)
      else failure("Unknown action type: #{action_type}")
      end

      # After player action, deduct AP and process NPC turn if applicable
      if result.success?
        deduct_ap(character, ap_cost)
        broadcaster.broadcast_ap_update(character, get_character_ap(character), AP_PER_TURN)

        # Process NPC turn if this is an NPC fight
        if npc_fight? && !should_end?
          process_npc_turn_after_delay
        end
      end

      result
    end

    # Check if this match involves an NPC opponent
    #
    # @return [Boolean] true if match has NPC participant
    def npc_fight?
      match.metadata&.dig("is_npc_fight") == true ||
        match.arena_participations.npcs.exists?
    end

    # Process the NPC's turn (called after player action)
    #
    # @return [Result, nil] result of NPC action or nil if no NPC
    def process_npc_turn
      npc_participation = match.arena_participations.npcs.first
      return nil unless npc_participation

      npc = npc_participation.npc_template
      return nil unless npc

      # Check if NPC is still alive
      if npc_participation.current_hp <= 0
        return nil
      end

      # Use AI to decide action
      ai = Arena::NpcCombatAi.new(
        npc_template: npc,
        match: match,
        rng: Random.new(match.id + Time.current.to_i)
      )

      decision = ai.decide_action

      case decision.action_type
      when :attack
        process_npc_attack(npc_participation, decision.target, decision.params)
      when :defend
        process_npc_defend(npc_participation)
      else
        process_npc_attack(npc_participation, decision.target, decision.params)
      end
    end

    # Start the match and begin combat
    #
    # @return [Boolean] true if match started successfully
    def start_match
      return false unless match.matching?

      match.update!(status: :live, started_at: Time.current)
      log_entry("system", nil, "The battle begins!")
      broadcaster.broadcast_match_started
      true
    end

    # End the match and determine winners
    #
    # @param winning_team [String, nil] the winning team or nil for draw
    # @param reason [Symbol] reason for ending (:normal, :timeout, :forfeit)
    # @return [Boolean] true if match ended successfully
    def end_match(winning_team = nil, reason: :normal)
      return false unless match.live?

      winning_team ||= determine_winner

      match.update!(
        status: :completed,
        ended_at: Time.current,
        winning_team: winning_team,
        timed_out: reason == :timeout
      )

      finalize_participations(winning_team)
      apply_trauma

      # End match messages
      case reason
      when :timeout
        # "Бой закончен по таймауту" - "Fight ended by timeout"
        log_entry("timeout", nil, "Fight ended by timeout")
      when :forfeit
        log_entry("system", nil, "Match ended by forfeit")
      else
        if winning_team
          log_entry("victory", nil, "Match ended! Winner: Team #{winning_team.upcase}")
        else
          log_entry("draw", nil, "Match ended in a draw!")
        end
      end

      broadcaster.broadcast_match_ended(winning_team, reason:)
      true
    end

    # End match due to timeout (called by ArenaTurnTimeoutJob)
    #
    # @return [Boolean] true if ended successfully
    def end_match_timeout
      end_match(nil, reason: :timeout)
    end

    # Check if match should end (all opponents defeated)
    #
    # @return [Boolean] true if match should end
    def should_end?
      teams = match.arena_participations.includes(:character).group_by(&:team)

      teams.values.any? do |team_participations|
        team_participations.all? { |p| participation_hp(p) <= 0 }
      end
    end

    # Determine winner based on remaining HP
    #
    # @return [String, nil] the winning team or nil for draw
    def determine_winner
      teams = match.arena_participations.includes(:character).group_by(&:team)

      team_health = teams.transform_values do |participations|
        participations.sum { |p| [participation_hp(p), 0].max }
      end

      max_health = team_health.values.max
      winners = team_health.select { |_team, health| health == max_health }

      (winners.size == 1) ? winners.keys.first : nil
    end

    private

    def process_turn(character, target: nil, attacks: [], blocks: [], skills: [])
      normalized_attacks = normalize_turn_attacks(attacks)
      normalized_blocks = normalize_turn_blocks(blocks)
      normalized_skills = Array(skills).reject(&:blank?)

      validation_errors = validate_turn_actions(normalized_attacks, normalized_blocks, normalized_skills)
      return failure(validation_errors.join(", ")) if validation_errors.any?

      turn_results = {
        attacks: [],
        blocks: normalized_blocks,
        skills: normalized_skills,
        total_ap: calculate_turn_ap_cost(normalized_attacks, normalized_blocks, normalized_skills)
      }

      if normalized_blocks.any?
        block_result = process_defend(character, block_parts: normalized_blocks.first[:body_parts])
        return block_result unless block_result.success?
      end

      normalized_attacks.each do |attack|
        attack_result = process_attack(
          character,
          target,
          attack_type: attack[:action_key].to_sym,
          body_part: attack[:body_part]
        )
        return attack_result unless attack_result.success?

        turn_results[:attacks] << attack_result.data
        break if should_end?
      end

      success(turn: true, **turn_results)
    end

    def process_attack(attacker, target, attack_type: :simple, body_part: "torso")
      # Find target - could be Character or NPC participation
      target_participation = find_target_participation(attacker, target)
      return failure("No valid target") unless target_participation

      # Check if target is NPC or player
      if target_participation.npc?
        process_attack_on_npc(attacker, target_participation, attack_type:, body_part:)
      else
        process_attack_on_player(attacker, target_participation.character, attack_type:, body_part:)
      end
    end

    def process_attack_on_player(attacker, target, attack_type: :simple, body_part: "torso")
      return failure("Cannot attack ally") if same_team?(attacker, target)
      return failure("Target is dead") if target.current_hp <= 0

      # Get attack type config
      attack_config = ATTACK_TYPES[attack_type.to_sym] || ATTACK_TYPES[:simple]

      # Check if target is blocking this body part
      blocked = target_blocking_part?(target, body_part)
      if blocked
        # Block message format: "{defender} blocked attack ({body_part}) from {attacker}"
        log_entry("block", target, "#{target.name} blocked attack (#{body_part}) from #{attacker.name}")
        broadcaster.broadcast_combat_action(attacker, "blocked", target, 0, body_part:)
        return success(blocked: true, body_part:, damage: 0)
      end

      # Calculate damage with attack type and body part modifiers
      base_damage = calculate_base_damage(attacker)
      base_damage = (base_damage * attack_config[:damage_mult]).round
      body_mult = BODY_PART_MULTIPLIERS[body_part] || 1.0
      base_damage = (base_damage * body_mult).round

      defense = calculate_defense(target)
      damage = [base_damage - defense, 1].max

      # Apply critical hit chance (2x damage)
      critical = rand < 0.1
      damage = (damage * 2).round if critical

      # Apply damage
      target.current_hp = [target.current_hp - damage, 0].max
      target.last_combat_at = Time.current
      target.save!

      # Combat log messages
      if critical
        # Format: "{attacker} CRITICAL HIT ({body_part}) {defender} for -{damage} [{hp}/{max_hp}]"
        log_entry("critical", attacker,
          "#{attacker.name} critical hit (#{body_part}) #{target.name} for -#{damage} [#{target.current_hp}/#{target.max_hp}]")
      else
        # Format: "{attacker} hit {defender} ({body_part}) for -{damage} [{hp}/{max_hp}]"
        log_entry("damage", attacker,
          "#{attacker.name} hit #{target.name} (#{body_part}) for -#{damage} [#{target.current_hp}/#{target.max_hp}]")
      end

      broadcaster.broadcast_vitals_update(target)
      broadcaster.broadcast_combat_action(attacker, "attack", target, damage, critical:, body_part:, attack_type:)

      # Check for death
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      success(damage:, critical:, target_hp: target.current_hp, body_part:, attack_type:)
    end

    # Check if target is blocking a specific body part
    def target_blocking_part?(character, body_part)
      return false unless character.metadata&.dig("blocking")

      blocked_parts = character.metadata["blocked_parts"] || []
      return false unless block_still_active?(character.metadata["block_until"])

      blocked = blocked_parts.include?(body_part)
      clear_blocking_state(character) if blocked
      blocked
    end

    def process_attack_on_npc(attacker, npc_participation, attack_type: :simple, body_part: "torso")
      npc = npc_participation.npc_template
      return failure("Target is dead") if npc_participation.current_hp <= 0

      # Get attack type config
      attack_config = ATTACK_TYPES[attack_type.to_sym] || ATTACK_TYPES[:simple]

      # Check if NPC is blocking this body part
      if npc_blocking_part?(npc_participation, body_part)
        log_entry("block", nil, "#{npc.name} blocked attack (#{body_part}) from #{attacker.name}")
        broadcast_npc_action(npc, "blocked", nil, 0, body_part:)
        return success(blocked: true, body_part:, damage: 0)
      end

      # Calculate damage with attack type and body part modifiers
      base_damage = calculate_base_damage(attacker)
      base_damage = (base_damage * attack_config[:damage_mult]).round
      body_mult = BODY_PART_MULTIPLIERS[body_part] || 1.0
      base_damage = (base_damage * body_mult).round

      npc_stats = npc_combat_stats(npc)
      defense = npc_stats[:defense] || 5

      damage = [base_damage - defense, 1].max

      # Apply critical hit chance (2x damage)
      critical = rand < 0.1
      damage = (damage * 2).round if critical

      # Apply damage to NPC
      new_hp = [npc_participation.current_hp - damage, 0].max
      npc_participation.current_hp = new_hp
      npc_participation.save!

      # Combat log messages
      if critical
        log_entry("critical", attacker,
          "#{attacker.name} critical hit (#{body_part}) #{npc.name} for -#{damage} [#{new_hp}/#{npc_participation.max_hp}]")
      else
        log_entry("damage", attacker,
          "#{attacker.name} hit #{npc.name} (#{body_part}) for -#{damage} [#{new_hp}/#{npc_participation.max_hp}]")
      end

      broadcast_npc_vitals_update(npc_participation)
      broadcaster.broadcast_combat_action(attacker, "attack", nil, damage, critical:, npc_target: npc.name, body_part:, attack_type:)

      # Check for NPC defeat
      if new_hp <= 0
        handle_npc_defeat(npc_participation)
        end_match if should_end?
      end

      success(damage:, critical:, target_hp: new_hp, body_part:, attack_type:)
    end

    # Check if NPC is blocking a specific body part
    def npc_blocking_part?(npc_participation, body_part)
      return false unless npc_participation.metadata&.dig("blocking")

      blocked_parts = npc_participation.metadata["blocked_parts"] || []
      return false unless block_still_active?(npc_participation.metadata["block_until"])

      blocked = blocked_parts.include?(body_part)
      clear_npc_blocking_state(npc_participation) if blocked
      blocked
    end

    def find_target_participation(attacker, target)
      attacker_team = match.arena_participations.find_by(character: attacker)&.team

      if target.is_a?(Character)
        match.arena_participations.find_by(character: target)
      elsif target.is_a?(ArenaParticipation)
        target
      else
        # Find default target (opponent with lowest HP)
        match.arena_participations
          .where.not(team: attacker_team)
          .min_by do |p|
            if p.npc?
              p.current_hp
            else
              p.character&.current_hp.to_i
            end
          end
      end
    end

    def broadcast_npc_vitals_update(npc_participation)
      npc = npc_participation.npc_template
      ActionCable.server.broadcast(
        match.broadcast_channel,
        {
          type: "npc_vitals_update",
          npc_name: npc.name,
          npc_id: npc.id,
          current_hp: npc_participation.current_hp,
          max_hp: npc_participation.max_hp,
          hp_percent: (npc_participation.current_hp.to_f / npc_participation.max_hp * 100).round
        }
      )
    end

    def handle_npc_defeat(npc_participation)
      npc = npc_participation.npc_template
      npc_participation.update!(result: "defeat", ended_at: Time.current)
      log_entry("defeat", nil, "#{npc.name} has been defeated!")

      ActionCable.server.broadcast(
        match.broadcast_channel,
        {
          type: "npc_defeated",
          npc_name: npc.name,
          npc_id: npc.id
        }
      )
    end

    def process_defend(character, block_parts: nil)
      # Default to single torso block if no parts specified
      block_parts ||= ["torso"]
      block_parts = Array(block_parts)
      block_parts = ["torso"] if block_parts.empty?

      # Apply defense buff for next incoming attack
      character.metadata ||= {}
      character.metadata["blocking"] = true
      character.metadata["blocked_parts"] = block_parts
      character.metadata["block_until"] = block_expires_at.iso8601
      character.save!

      parts_str = block_parts.join(", ")
      log_entry("action", character, "#{character.name} takes defensive stance (blocking: #{parts_str})")
      broadcaster.broadcast_combat_action(character, "defend", nil, 0, block_parts:)

      success(defending: true, block_parts:)
    end

    def process_skill(character, skill_id, target)
      return failure("No skill specified") unless skill_id

      # Find the skill
      skill = find_skill(character, skill_id)
      return failure("Skill not found or not unlocked") unless skill

      # Find target character
      target_char = find_target(target)
      return failure("Target not found") unless target_char

      # Create a battle wrapper for the arena match
      battle_wrapper = ArenaBattleWrapper.new(match)

      # Execute the skill
      executor = Game::Combat::SkillExecutor.new(
        caster: character,
        target: target_char,
        skill: skill,
        battle: battle_wrapper
      )

      result = executor.execute!
      return failure(result.message) unless result.success

      # Log the skill use
      log_entry("skill", character, "uses #{skill.name} on #{target_char.name}")

      # Broadcast skill effects
      broadcaster.broadcast_combat_action(character, "skill", target_char, result.damage, skill_name: skill.name)

      # Update vitals
      broadcaster.broadcast_vitals_update(character)
      broadcaster.broadcast_vitals_update(target_char)

      # Check for victory
      check_match_end!

      success(
        damage: result.damage,
        healing: result.healing,
        critical: result.critical,
        effects: result.effects_applied
      )
    end

    def find_skill(character, skill_id)
      skill_id = skill_id.to_s

      # Check if it's an ability (ability_123)
      if skill_id.start_with?("ability_")
        ability_id = skill_id.sub("ability_", "").to_i
        return character.character_class&.abilities&.find_by(id: ability_id, kind: "active")
      end

      # Check if it's a skill node (skill_123)
      if skill_id.start_with?("skill_")
        node_id = skill_id.sub("skill_", "").to_i
        return character.skill_nodes.where(node_type: "active").find_by(id: node_id)
      end

      # Try direct ID lookup
      character.skill_nodes.where(node_type: "active").find_by(id: skill_id) ||
        character.character_class&.abilities&.find_by(id: skill_id, kind: "active")
    end

    def find_target(target_id)
      return nil unless target_id

      match.arena_participations.includes(:character).find_by(character_id: target_id)&.character
    end

    def check_match_end!
      # Check if any participant is defeated
      match.arena_participations.includes(:character).each do |participation|
        if participation.character.current_hp <= 0
          # Mark as defeated
          participation.update!(result: "defeat", ended_at: Time.current)
        end
      end

      # Check if match should end
      alive = match.arena_participations.where(result: nil).count
      if alive <= 1
        winner = match.arena_participations.where(result: nil).first&.character
        end_match!(winner)
      end
    end

    def end_match!(winner)
      match.update!(
        status: :completed,
        ended_at: Time.current,
        winner_id: winner&.id
      )

      # Distribute rewards
      Arena::RewardsDistributor.new(match).distribute!

      broadcaster.broadcast_match_ended(winner)
    end

    # Wrapper to make ArenaMatch work with SkillExecutor
    class ArenaBattleWrapper
      attr_accessor :metadata

      def initialize(match)
        @match = match
        @metadata = match.metadata || {}
      end

      def id
        @match.id
      end

      def round_number
        @match.current_round || 1
      end

      def battle_participants
        @match.arena_participations
      end

      def combat_log_entries
        @match.combat_log_entries
      end

      def save!
        @match.update!(metadata: @metadata)
      end
    end

    def process_flee(character)
      return failure("Cannot flee from arena matches") if match.match_type == "duel"

      # Only allowed in sacrifice/FFA mode with HP penalty
      penalty = (character.max_hp * 0.2).round
      character.current_hp = [character.current_hp - penalty, 1].max
      character.save!

      log_entry("action", character, "attempts to flee (lost #{penalty} HP)")
      broadcaster.broadcast_vitals_update(character)

      # Remove from match
      participation = match.arena_participations.find_by(character:)
      participation.update!(result: "fled", ended_at: Time.current)

      success(fled: true, hp_penalty: penalty)
    end

    def calculate_base_damage(character)
      character.attack_power + rand(1..5)
    end

    def calculate_defense(character)
      character.defense
    end

    def find_default_target(attacker)
      attacker_team = match.arena_participations.find_by(character: attacker)&.team

      match.arena_participations
        .where.not(team: attacker_team)
        .includes(:character)
        .reject { |p| p.character.current_hp <= 0 }
        .min_by { |p| p.character.current_hp }
        &.character
    end

    def same_team?(char1, char2)
      p1 = match.arena_participations.find_by(character: char1)
      p2 = match.arena_participations.find_by(character: char2)
      p1&.team == p2&.team
    end

    def participant?(character)
      match.arena_participations.exists?(character:)
    end

    def handle_defeat(character)
      participation = match.arena_participations.find_by(character:)
      participation.update!(result: "defeat", ended_at: Time.current)
      log_entry("defeat", character, "has been defeated!")
      broadcaster.broadcast_defeat(character)
    end

    def finalize_participations(winning_team)
      match.arena_participations.each do |participation|
        if participation.result.blank? || participation.result == "pending"
          result = (participation.team == winning_team) ? "victory" : "defeat"
          rating_delta = calculate_rating_delta(participation, winning_team)
          participation.update!(
            result:,
            rating_delta:,
            ended_at: Time.current
          )
        end
      end
    end

    def calculate_rating_delta(participation, winning_team)
      # Simple ELO-like rating change
      if participation.team == winning_team
        rand(11..15)
      elsif winning_team.nil?
        0 # Draw
      else
        -rand(11..15)
      end
    end

    # Apply trauma (injury) effects after fight
    # Trauma affects HP recovery and XP loss based on trauma_percent
    def apply_trauma
      trauma_percent = match.trauma_percent || match.metadata&.dig("trauma_percent") || 30
      return if trauma_percent.zero?

      match.arena_participations.each do |p|
        next if p.npc?

        character = p.character
        is_loser = p.result == "defeat"

        # Winners get minor trauma, losers get full trauma
        effective_trauma = is_loser ? trauma_percent : (trauma_percent / 3.0).round

        # Apply HP reduction based on trauma
        # Higher trauma = lower HP after fight
        hp_loss = (character.max_hp * effective_trauma / 100.0).round
        new_hp = [character.current_hp - hp_loss, 1].max
        character.update!(current_hp: new_hp)

        # XP loss for losers based on trauma
        if is_loser && effective_trauma >= 30
          xp_loss = (character.experience.to_i * effective_trauma / 200.0).round
          character.update!(experience: [character.experience.to_i - xp_loss, 0].max)

          log_entry("trauma", character,
            "#{character.name} suffers trauma: -#{hp_loss} HP, -#{xp_loss} XP")
        else
          log_entry("trauma", character,
            "#{character.name} suffers minor trauma: -#{hp_loss} HP")
        end
      end
    end

    def log_entry(entry_type, actor, description)
      match.metadata ||= {}
      match.metadata["combat_log"] ||= []
      match.metadata["combat_log"] << {
        "type" => entry_type,
        "timestamp" => Time.current.strftime("%H:%M:%S"),
        "actor_id" => actor&.id,
        "actor_name" => actor&.name,
        "description" => description
      }
      match.save!
    end

    # Calculate AP cost for an action
    def calculate_ap_cost(action_type, params)
      case action_type.to_sym
      when :turn
        calculate_turn_ap_cost(
          normalize_turn_attacks(params[:attacks]),
          normalize_turn_blocks(params[:blocks]),
          Array(params[:skills]).reject(&:blank?)
        )
      when :attack
        attack_type = params[:attack_type]&.to_sym || :simple
        ATTACK_TYPES[attack_type]&.dig(:ap_cost) || 45
      when :defend
        block_parts = Array(params[:block_parts].presence || ["torso"])
        cost = Game::Combat::ActionCatalog.block_cost(body_parts: block_parts)
        cost.positive? ? cost : BLOCK_AP_COST
      when :skill
        50 # Default skill cost
      when :flee
        0 # No AP cost for flee
      else
        0
      end
    end

    def calculate_turn_ap_cost(attacks, blocks, skills)
      attack_cost = attacks.sum { |attack| attack_ap_cost(attack[:action_key]) }
      block_cost = blocks.sum { |block| block_ap_cost(block) }
      skill_cost = skills.sum { 50 }
      attack_cost + block_cost + attack_penalty(attacks.size) + skill_cost
    end

    def attack_ap_cost(action_key)
      Game::Combat::ActionCatalog.attack_cost(action_key) ||
        ATTACK_TYPES[action_key.to_sym]&.dig(:ap_cost) ||
        0
    end

    def block_ap_cost(block)
      cost = Game::Combat::ActionCatalog.block_cost(
        action_key: block[:action_key],
        body_parts: block[:body_parts]
      )
      cost.positive? ? cost : BLOCK_AP_COST
    end

    def attack_penalty(attack_count)
      penalties = Game::Combat::ActionCatalog.config["attack_penalties"] || []
      penalty_entry = penalties.find { |entry| entry["attacks"].to_i == attack_count }
      penalty_entry&.dig("penalty").to_i
    end

    def validate_turn_actions(attacks, blocks, skills)
      errors = []

      errors << "Choose at least one attack, block, or skill" if attacks.empty? && blocks.empty? && skills.empty?
      errors << "Only one block can be selected per turn" if blocks.size > 1
      errors << "Maximum 4 attacks per turn" if attacks.size > 4
      errors << "Magic/actions are not enabled for arena turn package yet" if skills.present?

      attack_parts = attacks.map { |attack| attack[:body_part] }
      if attack_parts.include?("head") && attack_parts.include?("legs")
        errors << "Cannot attack head and legs in the same turn"
      end

      attacks.each_with_index do |attack, index|
        unless BODY_PARTS.include?(attack[:body_part])
          errors << "Invalid body part for attack #{index + 1}: #{attack[:body_part]}"
        end

        unless ATTACK_TYPES.key?(attack[:action_key].to_sym)
          errors << "Invalid attack type for attack #{index + 1}: #{attack[:action_key]}"
        end
      end

      blocks.each_with_index do |block, index|
        if block[:body_parts].blank?
          errors << "Block #{index + 1} must cover at least one body part"
          next
        end

        block[:body_parts].each do |part|
          errors << "Invalid body part in block #{index + 1}: #{part}" unless BODY_PARTS.include?(part)
        end
      end

      total_ap = calculate_turn_ap_cost(attacks, blocks, skills)
      errors << "Actions exceed AP limit (#{total_ap}/#{AP_PER_TURN})" if total_ap > AP_PER_TURN

      errors
    end

    def normalize_turn_attacks(attacks)
      Array(attacks).filter_map do |attack|
        data = normalized_hash(attack)
        action_key = (data[:action_key] || data[:attack_type] || "simple").to_s
        body_part = (data[:body_part] || "torso").to_s
        next if action_key.blank? || action_key == "none" || body_part.blank? || body_part == "none"

        {action_key:, body_part:}
      end
    end

    def normalize_turn_blocks(blocks)
      Array(blocks).filter_map do |block|
        data = normalized_hash(block)
        body_parts = data[:body_parts] || data[:block_parts] || data[:parts] || data[:body_part]
        body_parts = body_parts.to_s.split(",") if body_parts.is_a?(String)
        body_parts = Game::Combat::ActionCatalog.canonical_parts(body_parts)
        next if body_parts.empty?

        action_key = data[:action_key] || Game::Combat::ActionCatalog.standard_block_for_parts(body_parts)&.fetch(:key)
        {action_key:, body_parts:}
      end
    end

    def normalized_hash(value)
      return {} if value.blank?
      return {body_parts: value.split(",")} if value.is_a?(String)

      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      value = value.to_h if value.respond_to?(:to_h)
      value.each_with_object({}) { |(key, item), memo| memo[key.to_sym] = item }
    end

    # Get character's current AP for this match
    def get_character_ap(character)
      participation = match.arena_participations.find_by(character: character)
      return AP_PER_TURN unless participation

      participation.metadata ||= {}
      [participation.metadata["current_ap"] || AP_PER_TURN, AP_PER_TURN].min
    end

    # Deduct AP from character
    def deduct_ap(character, amount)
      participation = match.arena_participations.find_by(character: character)
      return unless participation

      participation.metadata ||= {}
      current = [participation.metadata["current_ap"] || AP_PER_TURN, AP_PER_TURN].min
      participation.metadata["current_ap"] = [current - amount, 0].max
      participation.save!
    end

    # Reset AP to full at start of turn
    def reset_ap(character)
      participation = match.arena_participations.find_by(character: character)
      return unless participation

      participation.metadata ||= {}
      participation.metadata["current_ap"] = AP_PER_TURN
      participation.save!
    end

    def success(**data)
      Result.new(true, nil, data)
    end

    def failure(message)
      Result.new(false, message, {})
    end

    # Schedule NPC turn after a brief delay (for UI feedback)
    def process_npc_turn_after_delay
      # Process immediately for now, could be async with job
      # Small delay could be added with ActionCable streaming
      process_npc_turn
    end

    # Process NPC attack action
    def process_npc_attack(npc_participation, target, params)
      npc = npc_participation.npc_template
      target ||= find_player_target

      return failure("No valid target") unless target
      return failure("Target is dead") if target.current_hp <= 0

      # Calculate NPC damage
      npc_stats = npc_combat_stats(npc)
      body_part = params[:body_part] || "torso"

      if target_blocking_part?(target, body_part)
        log_entry("block", target, "#{target.name} blocked attack (#{body_part}) from #{npc.name}")
        broadcast_npc_action(npc, "blocked", target, 0, body_part:)
        return success(blocked: true, body_part:, damage: 0)
      end

      base_damage = npc_stats[:attack] + rand(1..5)
      defense = calculate_defense(target)
      damage = [base_damage - defense, 1].max

      # Apply critical hit chance
      crit_chance = npc_stats[:crit_chance] || 10
      critical = rand(100) < crit_chance
      damage = (damage * 1.5).round if critical

      # Apply damage to player
      target.current_hp = [target.current_hp - damage, 0].max
      target.last_combat_at = Time.current
      target.save!

      # Log and broadcast
      log_type = critical ? "critical" : "damage"
      log_entry(log_type, nil, "#{npc.name} attacks #{target.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if critical}")

      broadcaster.broadcast_vitals_update(target)
      broadcast_npc_action(npc, "attack", target, damage, critical: critical, body_part: body_part)

      # Check for player defeat
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      success(damage: damage, critical: critical, target_hp: target.current_hp)
    end

    # Process NPC defend action
    def process_npc_defend(npc_participation)
      npc = npc_participation.npc_template

      # Store defend state in participation metadata
      npc_participation.metadata ||= {}
      npc_participation.metadata["blocking"] = true
      npc_participation.metadata["blocked_parts"] = ["torso"]
      npc_participation.metadata["block_until"] = block_expires_at.iso8601
      npc_participation.save!

      log_entry("action", nil, "#{npc.name} takes a defensive stance")
      broadcast_npc_action(npc, "defend", nil, 0)

      success(defending: true)
    end

    # Find player target for NPC attack
    def find_player_target
      match.arena_participations
        .players
        .includes(:character)
        .reject { |p| p.character.current_hp <= 0 }
        .first
        &.character
    end

    # Get NPC combat stats
    def npc_combat_stats(npc)
      npc_config = Game::World::ArenaNpcConfig.find_npc(npc.npc_key)
      if npc_config
        Game::World::ArenaNpcConfig.extract_stats(npc_config)
      else
        level = npc.level || 1
        {
          attack: npc.metadata&.dig("base_damage") || (level * 3 + 5),
          defense: level * 2 + 3,
          agility: level + 5,
          hp: npc.health || (level * 10 + 20),
          crit_chance: 10
        }.with_indifferent_access
      end
    end

    # Broadcast NPC combat action
    def broadcast_npc_action(npc, action_type, target, damage, critical: false, body_part: nil, skill_name: nil)
      ActionCable.server.broadcast(
        match.broadcast_channel,
        {
          type: "npc_combat_action",
          npc_name: npc.name,
          npc_avatar: npc.avatar_emoji,
          action: action_type,
          target_name: target&.name,
          target_id: target&.id,
          damage: damage,
          critical: critical,
          body_part: body_part,
          skill_name: skill_name,
          timestamp: Time.current.strftime("%H:%M:%S")
        }
      )
    end

    def participation_hp(participation)
      participation.npc? ? participation.current_hp : participation.character&.current_hp.to_i
    end

    def block_still_active?(timestamp)
      return true if timestamp.blank?

      Time.parse(timestamp) > Time.current
    rescue ArgumentError, TypeError
      false
    end

    def block_expires_at
      timeout = match.turn_timeout_seconds || 120
      timeout.seconds.from_now
    end

    def clear_blocking_state(character)
      character.metadata.delete("blocking")
      character.metadata.delete("blocked_parts")
      character.metadata.delete("block_until")
      character.metadata.delete("defending")
      character.metadata.delete("defend_until")
      character.save!
    end

    def clear_npc_blocking_state(npc_participation)
      npc_participation.metadata.delete("blocking")
      npc_participation.metadata.delete("blocked_parts")
      npc_participation.metadata.delete("block_until")
      npc_participation.metadata.delete("defending")
      npc_participation.metadata.delete("defend_until")
      npc_participation.save!
    end

    # Simple result object for action outcomes
    Result = Struct.new(:success?, :error, :data) do
      def [](key)
        data[key]
      end
    end
  end
end
