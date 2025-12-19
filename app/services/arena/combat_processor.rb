# frozen_string_literal: true

module Arena
  # Processes combat actions during an arena match
  #
  # @example Process an attack action
  #   processor = Arena::CombatProcessor.new(match)
  #   result = processor.process_action(character, :attack, target: other_character)
  #
  class CombatProcessor
    attr_reader :match, :broadcaster

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
    # @return [Result] the result of the action
    def process_action(character, action_type, **params)
      return failure("Match is not active") unless match.live?
      return failure("Character not in this match") unless participant?(character)
      return failure("Character is dead") if character.current_hp <= 0

      result = case action_type.to_sym
      when :attack then process_attack(character, params[:target])
      when :defend then process_defend(character)
      when :skill then process_skill(character, params[:skill_id], params[:target])
      when :flee then process_flee(character)
      else failure("Unknown action type: #{action_type}")
      end

      # After player action, process NPC turn if this is an NPC fight
      if result.success? && npc_fight? && !should_end?
        process_npc_turn_after_delay
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
    # @return [Boolean] true if match ended successfully
    def end_match(winning_team = nil)
      return false unless match.live?

      winning_team ||= determine_winner

      match.update!(
        status: :completed,
        ended_at: Time.current,
        winning_team: winning_team
      )

      finalize_participations(winning_team)
      apply_trauma
      log_entry("system", nil, "Match ended! Winner: #{winning_team || "Draw"}")
      broadcaster.broadcast_match_ended(winning_team)
      true
    end

    # Check if match should end (all opponents defeated)
    #
    # @return [Boolean] true if match should end
    def should_end?
      teams = match.arena_participations.includes(:character).group_by(&:team)

      teams.values.any? do |team_participations|
        team_participations.all? { |p| p.character.current_hp <= 0 }
      end
    end

    # Determine winner based on remaining HP
    #
    # @return [String, nil] the winning team or nil for draw
    def determine_winner
      teams = match.arena_participations.includes(:character).group_by(&:team)

      team_health = teams.transform_values do |participations|
        participations.sum { |p| [p.character.current_hp, 0].max }
      end

      max_health = team_health.values.max
      winners = team_health.select { |_team, health| health == max_health }

      (winners.size == 1) ? winners.keys.first : nil
    end

    private

    def process_attack(attacker, target)
      # Find target - could be Character or NPC participation
      target_participation = find_target_participation(attacker, target)
      return failure("No valid target") unless target_participation

      # Check if target is NPC or player
      if target_participation.npc?
        process_attack_on_npc(attacker, target_participation)
      else
        process_attack_on_player(attacker, target_participation.character)
      end
    end

    def process_attack_on_player(attacker, target)
      return failure("Cannot attack ally") if same_team?(attacker, target)
      return failure("Target is dead") if target.current_hp <= 0

      # Calculate damage (simplified formula)
      base_damage = calculate_base_damage(attacker)
      defense = calculate_defense(target)
      damage = [base_damage - defense, 1].max

      # Apply critical hit chance
      critical = rand < 0.1
      damage = (damage * 1.5).round if critical

      # Apply damage
      target.current_hp = [target.current_hp - damage, 0].max
      target.last_combat_at = Time.current
      target.save!

      # Log and broadcast
      log_type = critical ? "critical" : "damage"
      log_entry(log_type, attacker, "attacks #{target.name} for #{damage} damage#{" (CRITICAL!)" if critical}")

      broadcaster.broadcast_vitals_update(target)
      broadcaster.broadcast_combat_action(attacker, "attack", target, damage, critical:)

      # Check for death
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      success(damage:, critical:, target_hp: target.current_hp)
    end

    def process_attack_on_npc(attacker, npc_participation)
      npc = npc_participation.npc_template
      return failure("Target is dead") if npc_participation.current_hp <= 0

      # Calculate damage
      base_damage = calculate_base_damage(attacker)
      npc_stats = npc_combat_stats(npc)
      defense = npc_stats[:defense] || 5

      # Check if NPC is defending
      if npc_defending?(npc_participation)
        defense = (defense * 1.5).round
        npc_participation.metadata.delete("defending")
        npc_participation.metadata.delete("defend_until")
      end

      damage = [base_damage - defense, 1].max

      # Apply critical hit chance
      critical = rand < 0.1
      damage = (damage * 1.5).round if critical

      # Apply damage to NPC
      new_hp = [npc_participation.current_hp - damage, 0].max
      npc_participation.current_hp = new_hp
      npc_participation.save!

      # Log and broadcast
      log_type = critical ? "critical" : "damage"
      log_entry(log_type, attacker, "attacks #{npc.name} for #{damage} damage#{" (CRITICAL!)" if critical}")

      broadcast_npc_vitals_update(npc_participation)
      broadcaster.broadcast_combat_action(attacker, "attack", nil, damage, critical:, npc_target: npc.name)

      # Check for NPC defeat
      if new_hp <= 0
        handle_npc_defeat(npc_participation)
        end_match if should_end?
      end

      success(damage:, critical:, target_hp: new_hp)
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
      npc_participation.update!(result: "defeated", ended_at: Time.current)
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

    def process_defend(character)
      # Apply defense buff for next incoming attack
      character.metadata ||= {}
      character.metadata["defending"] = true
      character.metadata["defend_until"] = 10.seconds.from_now.iso8601
      character.save!

      log_entry("action", character, "takes a defensive stance")
      broadcaster.broadcast_combat_action(character, "defend", nil, 0)

      success(defending: true)
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
          participation.update!(result: "defeated", ended_at: Time.current)
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
      # Base damage = character's attack stat + weapon bonus
      base = character.stats&.dig("attack") || 10
      weapon_bonus = character.equipped_weapon_damage || 0
      base + weapon_bonus + rand(1..5)
    end

    def calculate_defense(character)
      # Defense = character's defense stat + armor bonus
      # Check if defending
      base = character.stats&.dig("defense") || 5
      armor_bonus = character.equipped_armor_defense || 0
      defense = base + armor_bonus

      if character.metadata&.dig("defending") &&
          Time.parse(character.metadata["defend_until"]) > Time.current
        defense = (defense * 1.5).round
        character.metadata.delete("defending")
        character.metadata.delete("defend_until")
        character.save!
      end

      defense
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
      participation.update!(result: "defeated", ended_at: Time.current)
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

    def apply_trauma
      trauma_percent = match.metadata&.dig("trauma_percent") || 30
      return if trauma_percent.zero?

      match.arena_participations.where(result: "defeat").each do |p|
        # Apply trauma: temporary stat reduction or XP loss
        # This is a simplified version
        trauma_amount = (p.character.experience.to_i * trauma_percent / 100.0).round
        p.character.update!(
          experience: [p.character.experience.to_i - trauma_amount, 0].max
        )
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
      body_part = params[:body_part] || "torso"
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
      npc_participation.metadata["defending"] = true
      npc_participation.metadata["defend_until"] = 10.seconds.from_now.iso8601
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

    # Check if an NPC participation is defending
    def npc_defending?(npc_participation)
      return false unless npc_participation.metadata&.dig("defending")

      defend_until = npc_participation.metadata["defend_until"]
      return false unless defend_until

      Time.parse(defend_until) > Time.current
    rescue
      false
    end

    # Simple result object for action outcomes
    Result = Struct.new(:success?, :error, :data) do
      def [](key)
        data[key]
      end
    end
  end
end
