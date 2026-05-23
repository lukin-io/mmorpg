# frozen_string_literal: true

module Arena
  # Processes combat actions during an arena match
  # Implements Neverlands-style turn combat mechanics with:
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
    attr_reader :match, :broadcaster, :rng

    # Action Points per turn
    AP_PER_TURN = Game::Combat::ActionCatalog::DEFAULT_AP_PER_TURN
    BLOCK_AP_COST = 30
    BODY_PARTS = Game::Combat::ActionCatalog::BODY_PARTS

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
    def initialize(match, rng: Random.new)
      @match = match
      @rng = rng
      @broadcaster = Arena::CombatBroadcaster.new(match)
    end

    # Persist combat AP/cost profiles for every participant at match start.
    def prepare_combat_profiles!
      match.arena_participations.includes(:character, :npc_template).find_each do |participation|
        profile = Arena::CombatProfile.persist!(participation)
        participation.reload
        participation.metadata ||= {}
        next if participation.metadata.key?("current_ap")

        participation.update!(metadata: participation.metadata.merge("current_ap" => profile["ap_limit"]))
      end
    end

    def combat_profile_for(character_or_participation)
      participation = participation_from(character_or_participation)
      return {} unless participation

      Arena::CombatProfile.for_participation(participation, persist: true)
    end

    def combat_ap_limit_for(character_or_participation)
      combat_profile_for(character_or_participation).fetch("ap_limit", AP_PER_TURN)
    end

    def combat_attack_cost_for(character_or_participation, action_key)
      participation = participation_from(character_or_participation)
      return Game::Combat::ActionCatalog.attack_cost(action_key) unless participation

      Arena::CombatProfile.attack_cost(participation, action_key)
    end

    # Process a combat action from a character
    #
    # @param character [Character] the character performing the action
    # @param action_type [Symbol] the type of action (:attack, :defend, :turn, :flee)
    # @param params [Hash] additional parameters for the action
    #   - target: Character or ArenaParticipation to target
    #   - attack_type: :simple or :aimed (default :simple)
    #   - body_part: "head", "torso", "stomach", "legs" (default "torso")
    #   - block_parts: Array of body parts to block
    # @return [Result] the result of the action
    def process_action(character, action_type, **params)
      return failure("Бой не активен") unless match.live?
      return failure("Персонаж не участвует в этом бою") unless participant?(character)
      return failure("Персонаж повержен") if character.current_hp <= 0

      combat_profile_for(character)

      if action_type.to_sym == :turn && player_turn_commit_required?
        return process_player_turn_submission(
          character,
          target: params[:target],
          attacks: params[:attacks],
          blocks: params[:blocks],
          skills: params[:skills]
        )
      end

      # Check AP cost before processing
      ap_cost = calculate_ap_cost(action_type, params, actor: character)
      current_ap = get_character_ap(character)

      if current_ap < ap_cost
        return failure("Недостаточно ОД (нужно #{ap_cost}, есть #{current_ap})")
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
      when :flee then process_flee(character)
      else failure("Unknown action type: #{action_type}")
      end

      # After player action, deduct AP and process NPC turn if applicable
      if result.success?
        deduct_ap(character, ap_cost)
        broadcaster.broadcast_ap_update(character, get_character_ap(character), combat_ap_limit_for(character))

        if npc_response_required_for?(character) && !should_end?
          process_npc_turn_after_delay(character)
        end
      end

      result
    end

    # Check if this match involves any NPC participant.
    #
    # @return [Boolean] true if match has NPC participant
    def npc_fight?
      match.metadata&.dig("is_npc_fight") == true ||
        match.arena_participations.npcs.exists?
    end

    # Neverlands treats player, team, and NPC fights as the same fight
    # mechanism. Waiting is required when live player-controlled participants
    # exist on more than one side, regardless of whether NPCs are also present.
    def player_turn_commit_required?
      live_player_participations.map(&:team).uniq.size > 1
    end

    # Process the NPC's turn (called after player action)
    #
    # @return [Result, nil] result of NPC action or nil if no NPC
    def process_npc_turn(opposing_team: nil)
      npc_participation = npc_turn_participations(opposing_team:).first
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
      decision_params = decision.params || {}

      case decision.action_type
      when :attack
        attacks = Array(decision_params[:attacks]).presence
        if attacks
          process_npc_attack_sequence(npc_participation, decision.target, attacks, decision_params)
        else
          process_npc_attack(npc_participation, decision.target, decision_params)
        end
      when :defend
        process_npc_defend(npc_participation)
      else
        process_npc_attack(npc_participation, decision.target, decision_params)
      end
    end

    # Start the match and begin combat
    #
    # @return [Boolean] true if match started successfully
    def start_match
      return false unless match.pending? || match.matching?

      prepare_combat_profiles!

      match.update!(
        status: :live,
        started_at: Time.current,
        current_turn_started_at: Time.current,
        current_turn_number: match.current_turn_number.presence || 1,
        current_turn_team: nil
      )
      match.characters.update_all(in_combat: true, last_combat_at: Time.current)
      match.schedule_timeout_check
      log_entry("system", nil, "The fight begins!")
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

      # End match messages
      case reason
      when :timeout
        log_entry("timeout", nil, "Бой завершен по таймауту")
      when :forfeit
        log_entry("system", nil, "Бой завершен сдачей")
      else
        if winning_team
          if npc_fight?
            winner_name = match.arena_participations.find_by(team: winning_team)&.participant_name
            log_entry("victory", nil, "Победа: #{winner_name}.") if winner_name.present?
          end
          log_entry("victory", nil, "Бой завершен. Победитель: сторона #{winning_team.upcase}")
        else
          log_entry("draw", nil, "Бой завершился ничьей")
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

    # Resolve a Neverlands-style waiting timeout. The claimant must have
    # already submitted the current turn and be waiting for the opponent.
    def claim_timeout(character, mode: nil)
      return failure("Бой не активен") unless match.live?
      return failure("Персонаж не участвует в этом бою") unless participant?(character)
      return failure("Turn timer has not expired") unless match.turn_timed_out?

      participation = match.arena_participations.find_by(character:)
      return failure("Submit a turn before claiming timeout") unless pending_turn_data(participation).present?

      normalized_mode = mode.to_s == "draw" ? "draw" : "victory"
      winning_team = (normalized_mode == "draw") ? nil : participation.team

      description = if normalized_mode == "draw"
        "#{character.name} accepts a timeout draw."
      else
        "#{character.name} claims victory by timeout."
      end
      log_entry("timeout", character, description)
      end_match(winning_team, reason: :timeout)

      success(timeout_claimed: true, mode: normalized_mode, winning_team:)
    end

    def pending_player_turns?
      live_player_participations.any? { |participation| pending_turn_data(participation).present? }
    end

    def mark_timeout_claim_available!
      match.metadata ||= {}
      match.metadata["timeout_claim_available"] = true
      match.metadata["timeout_claim_turn_number"] = match.current_turn_number
      match.save!

      broadcaster.broadcast_timeout_claim_available
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
      normalized_skills = normalize_turn_skills(skills)

      validation_errors = validate_turn_actions(normalized_attacks, normalized_blocks, normalized_skills, actor: character)
      return failure(validation_errors.join(", ")) if validation_errors.any?
      mana_errors = validate_turn_mana(character, normalized_attacks, normalized_blocks, normalized_skills)
      return failure(mana_errors.join(", ")) if mana_errors.any?

      turn_results = {
        attacks: [],
        blocks: normalized_blocks,
        skills: [],
        total_ap: calculate_turn_ap_cost(normalized_attacks, normalized_blocks, normalized_skills, actor: character)
      }

      spend_turn_mana!(character, normalized_attacks, normalized_blocks, normalized_skills)

      normalized_skills.each do |skill|
        skill_result = process_turn_skill(character, skill, target)
        return skill_result unless skill_result.success?

        turn_results[:skills] << skill_result.data
        break if should_end?
      end

      if normalized_blocks.any?
        block_result = process_defend(
          character,
          block_parts: normalized_blocks.first[:body_parts],
          block_key: normalized_blocks.first[:action_key]
        )
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

    def process_player_turn_submission(character, target: nil, attacks: [], blocks: [], skills: [])
      participation = match.arena_participations.find_by(character:)
      return failure("Персонаж не участвует в этом бою") unless participation

      normalized_attacks = normalize_turn_attacks(attacks)
      normalized_blocks = normalize_turn_blocks(blocks)
      normalized_skills = normalize_turn_skills(skills)

      validation_errors = validate_turn_actions(normalized_attacks, normalized_blocks, normalized_skills, actor: character)
      return failure(validation_errors.join(", ")) if validation_errors.any?

      mana_errors = validate_turn_mana(character, normalized_attacks, normalized_blocks, normalized_skills)
      return failure(mana_errors.join(", ")) if mana_errors.any?

      ap_limit = combat_ap_limit_for(character)
      total_ap = calculate_turn_ap_cost(normalized_attacks, normalized_blocks, normalized_skills, actor: character)
      pending_turn = {
        "turn_number" => match.current_turn_number || 1,
        "target_participation_id" => target_participation_id(target),
        "attacks" => normalized_attacks.map { |attack| stringify_hash(attack) },
        "blocks" => normalized_blocks.map { |block| stringify_hash(block) },
        "skills" => normalized_skills.map { |skill| stringify_hash(skill) },
        "total_ap" => total_ap,
        "ap_limit" => ap_limit,
        "submitted_at" => Time.current.iso8601
      }

      resolved = false
      match.with_lock do
        participation.reload
        return failure("Turn already submitted; waiting for opponent") if pending_turn_current?(participation)

        spend_turn_mana!(character, normalized_attacks, normalized_blocks, normalized_skills)

        participation.metadata ||= {}
        participation.metadata["pending_turn"] = pending_turn
        participation.metadata["current_ap"] = [ap_limit - total_ap, 0].max
        participation.save!

        log_entry("action", character, "#{character.name} submitted a turn and waits for the opponent.")
        broadcaster.broadcast_ap_update(character, participation.metadata["current_ap"], ap_limit)
        broadcaster.broadcast_system_message("#{character.name} submitted a turn. Waiting for opponent.")

        resolved = resolve_pending_player_turns! if all_player_turns_ready?
      end

      success(waiting: !resolved, resolved:, total_ap:)
    end

    def resolve_pending_player_turns!
      participants = live_player_participations
      pending_turns = participants.index_with { |participation| pending_turn_data(participation) }
      round_number = match.current_turn_number || 1

      broadcaster.broadcast_system_message("Both sides committed. Resolving round #{round_number}.")

      pending_turns.each do |participation, turn|
        Array(turn["skills"]).each do |skill|
          next if participation.character.current_hp <= 0

          process_turn_skill(
            participation.character,
            normalized_hash(skill),
            target_from_pending_turn(participation, turn)
          )
          break if should_end?
        end
      end

      pending_turns.each do |participation, turn|
        block = Array(turn["blocks"]).first
        next if block.blank?

        block_data = normalized_hash(block)
        process_defend(participation.character, block_parts: block_data[:body_parts], block_key: block_data[:action_key])
      end

      pending_turns.each do |participation, turn|
        target = target_from_pending_turn(participation, turn)

        Array(turn["attacks"]).each do |attack|
          attack_data = normalized_hash(attack)
          attack_result = process_attack(
            participation.character,
            target,
            attack_type: attack_data[:action_key].to_sym,
            body_part: attack_data[:body_part]
          )
          break unless attack_result.success?
          break if should_end?
        end
      end

      clear_pending_player_turns!(participants)

      if should_end?
        end_match
      else
        match.update!(
          current_turn_started_at: Time.current,
          current_turn_number: (match.current_turn_number || 1) + 1,
          current_turn_team: nil
        )
        match.schedule_timeout_check
      end

      true
    end

    def process_attack(attacker, target, attack_type: :simple, body_part: "torso")
      return failure("Invalid attack type: #{attack_type}") if Game::Combat::ActionCatalog.attack_config(attack_type).blank?
      return failure("Invalid body part: #{body_part}") unless BODY_PARTS.include?(body_part.to_s)

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

      attacker_participation = match.arena_participations.find_by(character: attacker)
      target_participation = match.arena_participations.find_by(character: target)
      resolution = resolve_physical_attack(
        attacker_participation:,
        defender_participation: target_participation,
        action_key: attack_type,
        body_part:,
        block: blocking_data_for_character(target, body_part)
      )

      case resolution[:outcome]
      when :miss
        log_entry("miss", attacker, "#{attacker.name} missed #{target.name} (#{body_part})")
        broadcaster.broadcast_combat_action(attacker, "miss", target, 0, body_part:, miss: true)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", target, "#{target.name} dodged #{attacker.name}'s attack (#{body_part})")
        broadcaster.broadcast_combat_action(attacker, "dodge", target, 0, body_part:, dodge: true)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_blocking_state(target)
        log_entry("block", target, "#{target.name} blocked attack (#{body_part}) from #{attacker.name}")
        broadcaster.broadcast_combat_action(attacker, "blocked", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_blocking_state(target)
        log_entry("block_failed", target, "#{target.name} tried to block attack (#{body_part}) from #{attacker.name}, but it broke through")
      end

      # Apply damage
      target.current_hp = [target.current_hp - damage, 0].max
      target.last_combat_at = Time.current
      target.save!

      # Combat log messages
      if critical
        log_entry("critical", attacker, physical_hit_log(attacker.name, target.name, attack_type, body_part, damage, target.current_hp, target.max_hp, critical: true))
      else
        log_entry("damage", attacker, physical_hit_log(attacker.name, target.name, attack_type, body_part, damage, target.current_hp, target.max_hp))
      end

      broadcaster.broadcast_vitals_update(target)
      broadcaster.broadcast_combat_action(attacker, "attack", target, damage, critical:, body_part:, attack_type:)

      # Check for death
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      track_damage!(attacker_participation, target_participation, damage)

      success(**attack_result_payload(resolution, attack_type:, body_part:, target_hp: target.current_hp))
    end

    def process_attack_on_npc(attacker, npc_participation, attack_type: :simple, body_part: "torso")
      npc = npc_participation.npc_template
      return failure("Target is dead") if npc_participation.current_hp <= 0

      attacker_participation = match.arena_participations.find_by(character: attacker)
      resolution = resolve_physical_attack(
        attacker_participation:,
        defender_participation: npc_participation,
        action_key: attack_type,
        body_part:,
        block: blocking_data_for_npc(npc_participation, body_part)
      )

      case resolution[:outcome]
      when :miss
        log_entry("miss", attacker, "#{attacker.name} missed #{npc.name} (#{body_part})")
        broadcast_npc_action(npc, "miss", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", npc_participation, "#{npc.name} dodged #{attacker.name}'s attack (#{body_part})")
        broadcast_npc_action(npc, "dodge", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_npc_blocking_state(npc_participation)
        log_entry("block", npc_participation, "#{npc.name} blocked attack (#{body_part}) from #{attacker.name}")
        broadcast_npc_action(npc, "blocked", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_npc_blocking_state(npc_participation)
        log_entry("block_failed", npc_participation, "#{npc.name} tried to block attack (#{body_part}) from #{attacker.name}, but it broke through")
      end

      # Apply damage to NPC
      new_hp = [npc_participation.current_hp - damage, 0].max
      npc_participation.current_hp = new_hp
      npc_participation.save!

      # Combat log messages
      if critical
        log_entry("critical", attacker, physical_hit_log(attacker.name, npc.name, attack_type, body_part, damage, new_hp, npc_participation.max_hp, critical: true))
      else
        log_entry("damage", attacker, physical_hit_log(attacker.name, npc.name, attack_type, body_part, damage, new_hp, npc_participation.max_hp))
      end

      broadcast_npc_vitals_update(npc_participation)
      broadcaster.broadcast_combat_action(attacker, "attack", nil, damage, critical:, npc_target: npc.name, body_part:, attack_type:)

      # Check for NPC defeat
      if new_hp <= 0
        handle_npc_defeat(npc_participation, defeated_by: attacker)
        end_match if should_end?
      end

      track_damage!(attacker_participation, npc_participation, damage)

      success(**attack_result_payload(resolution, attack_type:, body_part:, target_hp: new_hp))
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

    def handle_npc_defeat(npc_participation, defeated_by: nil)
      npc = npc_participation.npc_template
      npc_participation.update!(result: "defeat", ended_at: Time.current)
      log_entry("defeat", npc_participation, "#{npc.name} has been defeated!")
      award_npc_loot!(npc, defeated_by) if defeated_by
      mark_world_tile_npc_defeated!(defeated_by) if defeated_by

      ActionCable.server.broadcast(
        match.broadcast_channel,
        {
          type: "npc_defeated",
          npc_name: npc.name,
          npc_id: npc.id
        }
      )
    end

    def mark_world_tile_npc_defeated!(defeated_by)
      return unless match.metadata&.dig("source") == "world_npc"

      tile_npc = TileNpc.find_by(id: match.metadata["tile_npc_id"])
      tile_npc&.defeat!(defeated_by)
    end

    def award_npc_loot!(npc, defeated_by)
      loot_table = Array(npc.loot_table)
      if loot_table.empty?
        log_entry("loot", defeated_by, "#{defeated_by.name} searched #{npc.name}. Result: nothing found.")
        return []
      end

      drops = roll_npc_loot(loot_table).filter_map do |entry|
        item_template = loot_item_template(entry)
        next unless item_template

        quantity = [entry.fetch("quantity", entry.fetch(:quantity, 1)).to_i, 1].max
        Game::Inventory::Manager.new(inventory: defeated_by.inventory).add_item!(item_template:, quantity:)
        {item: item_template, quantity:}
      rescue Game::Inventory::Manager::CapacityExceededError => e
        log_entry("loot", defeated_by, "#{defeated_by.name} searched #{npc.name}. #{e.message}.")
        nil
      end

      record_loot_drops!(defeated_by, npc, drops)

      if drops.empty?
        log_entry("loot", defeated_by, "#{defeated_by.name} searched #{npc.name}. Result: nothing found.")
      else
        found = drops.map do |drop|
          quantity = drop[:quantity] > 1 ? " x#{drop[:quantity]}" : ""
          "Вещь «#{drop[:item].name}»#{quantity}"
        end.join(", ")
        log_entry("loot", defeated_by, "#{defeated_by.name} searched #{npc.name}. Found #{found}.")
      end

      drops
    end

    def roll_npc_loot(loot_table)
      loot_table.select do |entry|
        chance = entry.fetch("chance", entry.fetch(:chance, 0)).to_f
        chance_percent = chance <= 1 ? chance * 100 : chance
        rng.rand(100) < chance_percent
      end
    end

    def loot_item_template(entry)
      key = entry["item_key"] || entry[:item_key] || entry["key"] || entry[:key]
      name = entry["item_name"] || entry[:item_name] || entry["name"] || entry[:name] || key.to_s.humanize
      return nil if key.blank? && name.blank?

      ItemTemplate.find_by(key:) || ItemTemplate.find_by(name:) || ItemTemplate.create!(
        key: key.presence || name.parameterize(separator: "_"),
        name:,
        item_type: entry["item_type"] || entry[:item_type] || "material",
        slot: "none",
        stat_modifiers: {},
        weight: [entry.fetch("weight", entry.fetch(:weight, 1)).to_i, 1].max,
        stack_limit: [entry.fetch("stack_limit", entry.fetch(:stack_limit, 99)).to_i, 1].max
      )
    end

    def record_loot_drops!(character, npc, drops)
      participation = match.arena_participations.find_by(character:)
      return unless participation

      participation.metadata ||= {}
      participation.metadata["loot_drops"] ||= []
      participation.metadata["loot_drops"] += drops.map do |drop|
        {
          "npc_key" => npc.npc_key,
          "item_key" => drop[:item].key,
          "item_name" => drop[:item].name,
          "quantity" => drop[:quantity],
          "awarded_at" => Time.current.iso8601
        }
      end
      participation.save!
    end

    def process_defend(character, block_parts: nil, block_key: nil)
      # Default to single torso block if no parts specified
      block_parts ||= ["torso"]
      block_parts = Array(block_parts)
      block_parts = ["torso"] if block_parts.empty?

      # Persist the selected block until the next incoming attack resolves.
      character.metadata ||= {}
      character.metadata["blocking"] = true
      character.metadata["blocked_parts"] = block_parts
      character.metadata["block_key"] = block_key || Game::Combat::ActionCatalog.standard_block_for_parts(block_parts)&.fetch(:key)
      block_config = Game::Combat::ActionCatalog.block_config(character.metadata["block_key"])
      character.metadata["block_table"] = block_config["block_table"].presence || "normal"
      character.metadata["block_until"] = block_expires_at.iso8601
      character.save!

      parts_str = block_parts.join(", ")
      log_entry("action", character, "#{character.name} takes defensive stance (blocking: #{parts_str})")
      broadcaster.broadcast_combat_action(character, "defend", nil, 0, block_parts:)

      success(defending: true, block_parts:)
    end

    def process_turn_skill(_character, skill, _target)
      key = skill[:key].to_s
      config = Game::Combat::ActionCatalog.magic_config(key)
      return failure("Magic/action not found: #{key}") if config.blank?

      failure("Magic/action slot requires source-captured resolver: #{config['name'] || key}")
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

      broadcaster.broadcast_match_ended(winner)
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

    def resolve_physical_attack(attacker_participation:, defender_participation:, action_key:, body_part:, block: nil)
      Arena::CombatResolver.new(match:, rng:).resolve_physical_attack(
        attacker_participation:,
        defender_participation:,
        action_key:,
        body_part:,
        block:
      )
    end

    def attack_result_payload(resolution, attack_type:, body_part:, **extra)
      resolution.merge(attack_type:, body_part:, **extra)
    end

    def blocking_data_for_character(character, body_part = nil)
      return nil unless character&.metadata&.dig("blocking")
      return nil unless block_still_active?(character.metadata["block_until"])

      body_parts = Array(character.metadata["blocked_parts"]).map(&:to_s)
      return nil if body_part.present? && !body_parts.include?(body_part.to_s)

      {
        "action_key" => character.metadata["block_key"] ||
          Game::Combat::ActionCatalog.standard_block_for_parts(body_parts)&.fetch(:key),
        "body_parts" => body_parts,
        "block_table" => character.metadata["block_table"] || "normal"
      }
    end

    def blocking_data_for_npc(npc_participation, body_part = nil)
      return nil unless npc_participation&.metadata&.dig("blocking")
      return nil unless block_still_active?(npc_participation.metadata["block_until"])

      body_parts = Array(npc_participation.metadata["blocked_parts"]).map(&:to_s)
      return nil if body_part.present? && !body_parts.include?(body_part.to_s)

      {
        "action_key" => npc_participation.metadata["block_key"] ||
          Game::Combat::ActionCatalog.standard_block_for_parts(body_parts)&.fetch(:key),
        "body_parts" => body_parts,
        "block_table" => npc_participation.metadata["block_table"] || "normal"
      }
    end

    def track_damage!(attacker_participation, defender_participation, damage)
      return if damage.to_i <= 0

      if attacker_participation
        attacker_participation.reload
        attacker_participation.metadata ||= {}
        attacker_participation.metadata["damage_dealt"] = attacker_participation.metadata["damage_dealt"].to_i + damage.to_i
        attacker_participation.save!
      end

      if defender_participation
        defender_participation.reload
        defender_participation.metadata ||= {}
        defender_participation.metadata["damage_taken"] = defender_participation.metadata["damage_taken"].to_i + damage.to_i
        defender_participation.save!
      end
    end

    def physical_hit_log(attacker_name, target_name, attack_type, body_part, damage, current_hp, max_hp, critical: false)
      action_name = Game::Combat::ActionCatalog.attack_config(attack_type)["name"].presence
      if action_name.present? && !%w[simple aimed].include?(attack_type.to_s)
        verb = critical ? "critical #{action_name}" : "uses #{action_name}"
        "#{attacker_name} #{verb} (#{body_part}) #{target_name} for -#{damage} [#{current_hp}/#{max_hp}]"
      elsif critical
        "#{attacker_name} critical hit (#{body_part}) #{target_name} for -#{damage} [#{current_hp}/#{max_hp}]"
      else
        "#{attacker_name} hit #{target_name} (#{body_part}) for -#{damage} [#{current_hp}/#{max_hp}]"
      end
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
          result = if winning_team.nil?
            "draw"
          elsif participation.team == winning_team
            "victory"
          else
            "defeat"
          end
          participation.update!(
            result:,
            ended_at: Time.current
          )
        end
      end
    end

    def log_entry(entry_type, actor, description)
      combat_log_recorder.record!(
        entry_type:,
        actor:,
        description:
      )
    end

    def combat_log_recorder
      @combat_log_recorder ||= Arena::CombatLogRecorder.new(match)
    end

    # Calculate AP cost for an action
    def calculate_ap_cost(action_type, params, actor: nil)
      case action_type.to_sym
      when :turn
        calculate_turn_ap_cost(
          normalize_turn_attacks(params[:attacks]),
          normalize_turn_blocks(params[:blocks]),
          normalize_turn_skills(params[:skills]),
          actor:
        )
      when :attack
        attack_type = params[:attack_type]&.to_sym || :simple
        attack_ap_cost(attack_type, actor:)
      when :defend
        block_parts = Array(params[:block_parts].presence || ["torso"])
        cost = Game::Combat::ActionCatalog.block_cost(body_parts: block_parts)
        cost.positive? ? cost : BLOCK_AP_COST
      when :flee
        0 # No AP cost for flee
      else
        0
      end
    end

    def calculate_turn_ap_cost(attacks, blocks, skills, actor: nil)
      attack_cost = attacks.sum { |attack| attack_ap_cost(attack[:action_key], actor:) }
      block_cost = blocks.sum { |block| block_ap_cost(block) }
      skill_cost = skills.sum { |skill| magic_action_ap_cost(skill[:key]) }
      attack_cost + block_cost + attack_penalty(attacks.size) + skill_cost
    end

    def attack_ap_cost(action_key, actor: nil)
      if %w[simple aimed].include?(action_key.to_s) && actor.present?
        return combat_attack_cost_for(actor, action_key)
      end

      Game::Combat::ActionCatalog.attack_cost(action_key)
    end

    def attack_mana_cost(action_key)
      Game::Combat::ActionCatalog.attack_mana_cost(action_key)
    end

    def block_ap_cost(block)
      cost = Game::Combat::ActionCatalog.block_cost(
        action_key: block[:action_key],
        body_parts: block[:body_parts]
      )
      cost.positive? ? cost : BLOCK_AP_COST
    end

    def magic_action_ap_cost(action_key)
      Game::Combat::ActionCatalog.magic_cost(action_key)
    end

    def magic_action_mana_cost(action_key)
      Game::Combat::ActionCatalog.magic_mana_cost(action_key)
    end

    def block_mana_cost(block)
      Game::Combat::ActionCatalog.block_config(block[:action_key]).fetch("mana_cost", 0).to_i
    end

    def calculate_turn_mana_cost(attacks, blocks, skills)
      attacks.sum { |attack| attack_mana_cost(attack[:action_key]) } +
        blocks.sum { |block| block_mana_cost(block) } +
        skills.sum { |skill| magic_action_mana_cost(skill[:key]) }
    end

    def attack_penalty(attack_count)
      Game::Combat::ActionCatalog.attack_penalty(attack_count)
    end

    def validate_turn_actions(attacks, blocks, skills, actor: nil)
      errors = []

      errors << "Choose at least one attack, block, or skill" if attacks.empty? && blocks.empty? && skills.empty?
      unless valid_neverlands_turn_shape?(attacks, blocks, skills)
        errors << "Choose at least one valid attack, block, or magic/action slot"
      end
      errors << "Only one block can be selected per turn" if blocks.size > 1
      errors << "Maximum 4 attacks per turn" if attacks.size > 4
      attack_parts = attacks.map { |attack| attack[:body_part] }
      if attack_parts.include?("head") && attack_parts.include?("legs")
        errors << "Cannot attack head and legs in the same turn"
      end

      attacks.each_with_index do |attack, index|
        unless BODY_PARTS.include?(attack[:body_part])
          errors << "Invalid body part for attack #{index + 1}: #{attack[:body_part]}"
        end

        unless Game::Combat::ActionCatalog.attack_config(attack[:action_key]).present?
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

      skills.each_with_index do |skill, index|
        unless Game::Combat::ActionCatalog.magic_config(skill[:key]).present?
          errors << "Invalid magic/action slot #{index + 1}: #{skill[:key]}"
        end
      end

      total_ap = calculate_turn_ap_cost(attacks, blocks, skills, actor:)
      ap_limit = actor.present? ? combat_ap_limit_for(actor) : AP_PER_TURN
      errors << "Actions exceed AP limit (#{total_ap}/#{ap_limit})" if total_ap > ap_limit

      errors
    end

    def valid_neverlands_turn_shape?(attacks, blocks, skills)
      return true if attacks.size > 1
      return true if attacks.any? && blocks.any?
      return true if attacks.any? && skills.any?
      return true if blocks.any? && skills.any?
      return true if skills.any? && attacks.empty? && blocks.empty?
      return true if attacks.one? && blocks.empty? && skills.empty? && attack_mana_cost(attacks.first[:action_key]).positive?

      false
    end

    def validate_turn_mana(character, attacks, blocks, skills)
      total_mana = calculate_turn_mana_cost(attacks, blocks, skills)
      errors = []

      if total_mana > character.current_mp.to_i
        errors << "Недостаточно MP (нужно #{total_mana}, есть #{character.current_mp.to_i})"
      end

      magic_limit = combat_profile_for(character).fetch("max_magic_mana", character.max_mp.to_i).to_i
      expensive_actions = [
        *attacks.filter_map { |attack| attack_mana_cost(attack[:action_key]) },
        *blocks.filter_map { |block| block_mana_cost(block) },
        *skills.filter_map { |skill| magic_action_mana_cost(skill[:key]) }
      ].select { |cost| cost.to_i > magic_limit }
      if expensive_actions.any?
        errors << "Magic/action mana exceeds fight limit (#{expensive_actions.max}/#{magic_limit})"
      end

      errors
    end

    def spend_turn_mana!(character, attacks, blocks, skills)
      total_mana = calculate_turn_mana_cost(attacks, blocks, skills)
      return if total_mana.zero?

      character.update!(current_mp: [character.current_mp.to_i - total_mana, 0].max)
      broadcaster.broadcast_vitals_update(character)
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

    def normalize_turn_skills(skills)
      Array(skills).filter_map do |skill|
        data = normalized_hash(skill)
        key = (data[:key] || data[:action_key]).to_s
        next if key.blank? || key == "none"

        {
          key:,
          target_id: data[:target_id],
          target_participation_id: data[:target_participation_id]
        }.compact
      end
    end

    def normalized_hash(value)
      return {} if value.blank?
      return {body_parts: value.split(",")} if value.is_a?(String)

      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      value = value.to_h if value.respond_to?(:to_h)
      value.each_with_object({}) { |(key, item), memo| memo[key.to_sym] = item }
    end

    def stringify_hash(hash)
      hash.each_with_object({}) { |(key, value), memo| memo[key.to_s] = value }
    end

    def pending_turn_current?(participation)
      pending_turn_data(participation).present?
    end

    def pending_turn_data(participation)
      pending = participation.metadata&.dig("pending_turn")
      return nil unless pending.present?
      return nil unless pending["turn_number"].to_i == (match.current_turn_number || 1).to_i

      pending
    end

    def all_player_turns_ready?
      participants = live_player_participations
      return false if participants.size < 2

      participants.all? { |participation| pending_turn_data(participation).present? }
    end

    def live_player_participations
      match.arena_participations.players.includes(:character).select do |participation|
        participation.character&.current_hp.to_i.positive?
      end
    end

    def clear_pending_player_turns!(participations)
      participations.each do |participation|
        ap_limit = combat_ap_limit_for(participation)
        participation.metadata ||= {}
        participation.metadata.delete("pending_turn")
        participation.metadata["current_ap"] = ap_limit
        participation.save!

        broadcaster.broadcast_ap_update(participation.character, ap_limit, ap_limit)
      end
    end

    def target_participation_id(target)
      case target
      when ArenaParticipation
        target.id
      when Character
        match.arena_participations.find_by(character: target)&.id
      else
        nil
      end
    end

    def target_from_pending_turn(participation, turn)
      target_participation = match.arena_participations.find_by(id: turn["target_participation_id"])
      return target_participation if target_participation

      find_default_target(participation.character)
    end

    # Get character's current AP for this match
    def get_character_ap(character)
      participation = match.arena_participations.find_by(character: character)
      return AP_PER_TURN unless participation

      ap_limit = combat_ap_limit_for(participation)
      participation.metadata ||= {}
      [participation.metadata["current_ap"] || ap_limit, ap_limit].min
    end

    # Deduct AP from character
    def deduct_ap(character, amount)
      participation = match.arena_participations.find_by(character: character)
      return unless participation

      ap_limit = combat_ap_limit_for(participation)
      participation.metadata ||= {}
      current = [participation.metadata["current_ap"] || ap_limit, ap_limit].min
      participation.metadata["current_ap"] = [current - amount, 0].max
      participation.save!
    end

    # Reset AP to full at start of turn
    def reset_ap(character)
      participation = match.arena_participations.find_by(character: character)
      return unless participation

      ap_limit = combat_ap_limit_for(participation)
      participation.metadata ||= {}
      participation.metadata["current_ap"] = ap_limit
      participation.save!
    end

    def participation_from(character_or_participation)
      case character_or_participation
      when ArenaParticipation then character_or_participation
      when Character then match.arena_participations.find_by(character: character_or_participation)
      end
    end

    def success(**data)
      Result.new(true, nil, data)
    end

    def failure(message)
      Result.new(false, message, {})
    end

    # Schedule NPC turn after a brief delay (for UI feedback)
    def process_npc_turn_after_delay(character)
      # Process immediately for now, could be async with job
      # Small delay could be added with ActionCable streaming
      process_npc_turn(opposing_team: match.arena_participations.find_by(character:)&.team)
    end

    def npc_response_required_for?(character)
      return false if player_turn_commit_required?

      team = match.arena_participations.find_by(character:)&.team
      npc_turn_participations(opposing_team: team).any?
    end

    def npc_turn_participations(opposing_team: nil)
      scope = match.arena_participations.npcs.includes(:npc_template)
      scope = scope.where.not(team: opposing_team) if opposing_team.present?
      scope.select { |participation| participation.current_hp.positive? }
    end

    def process_npc_attack_sequence(npc_participation, target, attacks, base_params = {})
      results = []

      Array(attacks).each do |attack|
        break if should_end?
        break if npc_participation.reload.current_hp <= 0

        attack_data = normalized_hash(attack)
        params = base_params.merge(
          body_part: attack_data[:body_part] || base_params[:body_part] || "torso",
          attack_type: attack_data[:action_key] || attack_data[:attack_type] || base_params[:attack_type] || "simple"
        )

        result = process_npc_attack(npc_participation, target, params)
        break unless result&.success?

        results << result.data
        target.reload if target.respond_to?(:reload)
        break if target.respond_to?(:current_hp) && target.current_hp <= 0
      end

      success(npc_turn: true, attacks: results)
    end

    # Process NPC attack action
    def process_npc_attack(npc_participation, target, params)
      npc = npc_participation.npc_template
      target ||= find_player_target

      return failure("No valid target") unless target
      return failure("Target is dead") if target.current_hp <= 0

      body_part = params[:body_part] || "torso"
      attack_type = params[:attack_type] || "simple"
      target_participation = match.arena_participations.find_by(character: target)
      resolution = resolve_physical_attack(
        attacker_participation: npc_participation,
        defender_participation: target_participation,
        action_key: attack_type,
        body_part:,
        block: blocking_data_for_character(target, body_part)
      )

      case resolution[:outcome]
      when :miss
        log_entry("miss", npc_participation, "#{npc.name} missed #{target.name} (#{body_part})")
        broadcast_npc_action(npc, "miss", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", target, "#{target.name} dodged #{npc.name}'s attack (#{body_part})")
        broadcast_npc_action(npc, "dodge", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_blocking_state(target)
        log_entry("block", target, "#{target.name} blocked attack (#{body_part}) from #{npc.name}")
        broadcast_npc_action(npc, "blocked", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_blocking_state(target)
        log_entry("block_failed", target, "#{target.name} tried to block attack (#{body_part}) from #{npc.name}, but it broke through")
      end

      # Apply damage to player
      target.current_hp = [target.current_hp - damage, 0].max
      target.last_combat_at = Time.current
      target.save!

      # Log and broadcast
      log_type = critical ? "critical" : "damage"
      log_entry(log_type, npc_participation, "#{npc.name} attacks #{target.name}'s #{body_part} for #{damage} damage#{" (CRITICAL!)" if critical}")

      broadcaster.broadcast_vitals_update(target)
      broadcast_npc_action(npc, "attack", target, damage, critical: critical, body_part: body_part)
      track_damage!(npc_participation, target_participation, damage)

      # Check for player defeat
      if target.current_hp <= 0
        handle_defeat(target)
        end_match if should_end?
      end

      success(**attack_result_payload(resolution, attack_type:, body_part:, target_hp: target.current_hp))
    end

    # Process NPC defend action
    def process_npc_defend(npc_participation)
      npc = npc_participation.npc_template

      # Store defend state in participation metadata
      npc_participation.metadata ||= {}
      npc_participation.metadata["blocking"] = true
      npc_participation.metadata["blocked_parts"] = ["torso"]
      npc_participation.metadata["block_key"] = "torso_block"
      npc_participation.metadata["block_table"] = "normal"
      npc_participation.metadata["block_until"] = block_expires_at.iso8601
      npc_participation.save!

      log_entry("action", npc_participation, "#{npc.name} takes a defensive stance")
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
        npc.combat_stats
      end
    end

    # Broadcast NPC combat action
    def broadcast_npc_action(npc, action_type, target, damage, critical: false, body_part: nil)
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
