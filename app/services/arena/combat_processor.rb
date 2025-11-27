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

      case action_type.to_sym
      when :attack then process_attack(character, params[:target])
      when :defend then process_defend(character)
      when :skill then process_skill(character, params[:skill_id], params[:target])
      when :flee then process_flee(character)
      else failure("Unknown action type: #{action_type}")
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
      log_entry("system", nil, "Match ended! Winner: #{winning_team || 'Draw'}")
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

      winners.size == 1 ? winners.keys.first : nil
    end

    private

    def process_attack(attacker, target)
      target ||= find_default_target(attacker)
      return failure("No valid target") unless target
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
      log_entry(log_type, attacker, "attacks #{target.name} for #{damage} damage#{' (CRITICAL!)' if critical}")

      broadcaster.broadcast_vitals_update(target)
      broadcaster.broadcast_combat_action(attacker, "attack", target, damage, critical:)

      # Check for death
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      success(damage:, critical:, target_hp: target.current_hp)
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
      # TODO: Implement skill system
      failure("Skills not yet implemented")
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
          result = participation.team == winning_team ? "victory" : "defeat"
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
        10 + rand(1..5)
      elsif winning_team.nil?
        0 # Draw
      else
        -(10 + rand(1..5))
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

    # Simple result object for action outcomes
    Result = Struct.new(:success?, :error, :data) do
      def [](key)
        data[key]
      end
    end
  end
end
