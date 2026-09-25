# frozen_string_literal: true

module Arena
  # Processes combat actions during an arena match
  # Implements Neverlands-style turn combat mechanics with:
  # - Body part targeting (head, torso, stomach, legs)
  # - Attack types (simple, aimed) with different AP costs
  # - Block types (single and combo coverage)
  # - Standardized combat log messages
  #
  # @example Process a player turn intent
  #   processor = Arena::CombatProcessor.new(match)
  #   result = processor.process_player_intent(
  #     character,
  #     :turn,
  #     target: other_character,
  #     attacks: [{action_key: "simple", body_part: "torso"}],
  #     blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
  #   )
  #
  class CombatProcessor
    attr_reader :match, :broadcaster, :rng, :event_publisher, :loot_awarder_class, :logger

    # Action Points per turn
    AP_PER_TURN = Game::Combat::ActionCatalog::DEFAULT_AP_PER_TURN
    BLOCK_AP_COST = 30
    BODY_PARTS = Game::Combat::ActionCatalog::BODY_PARTS
    PLAYER_INTENT_ACTIONS = %i[turn surrender].freeze
    AUTOMATIC_WINNER = Object.new.freeze

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
    def initialize(
      match,
      rng: Random.new,
      event_publisher: Chat::EventPublisher.new,
      loot_awarder_class: Arena::NpcLootAwarder,
      broadcaster: nil,
      logger: Rails.logger
    )
      @match = match
      @rng = rng
      @event_publisher = event_publisher
      @loot_awarder_class = loot_awarder_class
      @broadcaster = broadcaster || Arena::CombatBroadcaster.new(match)
      @logger = logger
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

    # Process a complete player-facing combat intent. Direct attack and defend
    # actions are internal resolution primitives; exposing them would bypass
    # the captured turn-shape and profile validation applied to a turn package.
    #
    # @param character [Character] the character submitting the intent
    # @param action_type [String, Symbol] turn or surrender
    # @param params [Hash] target and complete turn-package fields
    # @return [Result] the validated action result
    def process_player_intent(character, action_type, **params)
      normalized_action_type = action_type.to_s.to_sym
      return failure(I18n.t("game.fight.errors.unsupported_intent")) unless PLAYER_INTENT_ACTIONS.include?(normalized_action_type)

      process_action(character, normalized_action_type, **params)
    end

    # Process a combat resolution primitive. Player-facing entry points must
    # call +process_player_intent+ so direct attack/defend cannot bypass a
    # complete Neverlands-style turn package.
    #
    # @param character [Character] the character performing the action
    # @param action_type [Symbol] the type of action (:attack, :defend, :turn, :surrender)
    # @param params [Hash] additional parameters for the action
    #   - target: Character or ArenaParticipation to target
    #   - attack_type: :simple or :aimed (default :simple)
    #   - body_part: "head", "torso", "stomach", "legs" (default "torso")
    #   - block_parts: Array of body parts to block
    # @return [Result] the result of the action
    def process_action(character, action_type, **params)
      return failure(I18n.t("game.fight.errors.not_active")) unless match.live?
      return failure(I18n.t("game.fight.errors.not_participating")) unless participant?(character)
      return failure(I18n.t("game.fight.errors.character_defeated")) if character.current_hp <= 0

      combat_profile_for(character)

      return process_surrender(character) if action_type.to_sym == :surrender

      if action_type.to_sym == :turn && player_turn_commit_required?
        return process_player_turn_submission(
          character,
          target: params[:target],
          attacks: params[:attacks],
          blocks: params[:blocks],
          skills: params[:skills],
          expected_turn_number: params[:expected_turn_number]
        )
      end

      if action_type.to_sym == :turn && npc_fight?
        return process_solo_npc_turn(
          character,
          target: params[:target],
          attacks: params[:attacks],
          blocks: params[:blocks],
          skills: params[:skills],
          expected_turn_number: params[:expected_turn_number]
        )
      end

      # Check AP cost before processing
      ap_cost = calculate_ap_cost(action_type, params, actor: character)
      current_ap = get_character_ap(character)

      if current_ap < ap_cost
        return failure(I18n.t("game.fight.errors.not_enough_ap", need: ap_cost, have: current_ap))
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
      else failure(I18n.t("game.fight.errors.unknown_action", action: action_type))
      end

      # After player action, deduct AP and process NPC turn if applicable
      if result.success?
        deduct_ap(character, ap_cost)
        broadcaster.broadcast_ap_update(character, get_character_ap(character), combat_ap_limit_for(character))

        if npc_response_required_for?(character) && !should_end?
          process_npc_turn_after_delay(
            character,
            only_participation_ids: counter_npc_participation_ids(params[:target])
          )
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
    def process_npc_turn(opposing_team: nil, only_participation_ids: nil)
      results = []

      npc_turn_participations(opposing_team:).each do |npc_participation|
        break if should_end?
        if only_participation_ids.present? && !only_participation_ids.include?(npc_participation.id)
          next
        end

        result = process_single_npc_turn(npc_participation)
        results << result if result
      end

      return nil if results.empty?
      return results.first if results.one?

      success(
        npc_turn: true,
        actions: results.map(&:data)
      )
    end

    # Start the match and begin combat
    #
    # @return [Boolean] true if match started successfully
    def start_match
      return false unless match.reload.pending? || match.matching?

      prepare_combat_profiles!

      started = ApplicationRecord.transaction do
        match.lock!
        next false unless match.pending? || match.matching?

        started_at = Time.current
        match.update!(
          status: :live,
          started_at:,
          current_turn_started_at: started_at,
          current_turn_number: [match.current_turn_number.to_i, 1].max,
          current_turn_team: nil
        )
        match.characters.update_all(in_combat: true, last_combat_at: started_at)
        match.arena_applications.matched.update_all(
          status: ArenaApplication.statuses.fetch("started"),
          starts_at: started_at,
          updated_at: started_at
        )
        log_entry("system", nil, Arena::CombatLogMessages.fight_begins)
        true
      end

      return false unless started

      ActiveRecord.after_all_transactions_commit do
        schedule_timeout_check_safely
        broadcaster.broadcast_match_started
        broadcaster.broadcast_state_refresh(reason: :match_started)
      end
      true
    end

    # End the match and determine winners
    #
    # @param winning_team [String, nil] the winning team, nil for an explicit
    #   draw, or omitted to determine the winner from the surviving teams
    # @param reason [Symbol] reason for ending (:normal, :timeout, :forfeit)
    # @return [Boolean] true if match ended successfully
    def end_match(winning_team = AUTOMATIC_WINNER, reason: :normal)
      automatic_winner = winning_team.equal?(AUTOMATIC_WINNER)
      resolved_winning_team = nil
      ended = ApplicationRecord.transaction do
        match.lock!
        next false unless match.live?

        resolved_winning_team = automatic_winner ? determine_winner : winning_team

        match.update!(
          status: :completed,
          ended_at: Time.current,
          winning_team: resolved_winning_team,
          timed_out: reason == :timeout
        )
        match.arena_applications.matched.update_all(
          status: ArenaApplication.statuses.fetch("started"),
          updated_at: Time.current
        )

        finalize_participations(resolved_winning_team)
        finalize_rewards!(resolved_winning_team)
        cleanup_personal_world_npc!
        match.characters.update_all(in_combat: false, updated_at: Time.current)

        # End match messages
        case reason
        when :timeout
          log_entry("timeout", nil, Arena::CombatLogMessages.fight_timeout)
        when :forfeit
          log_entry("system", nil, Arena::CombatLogMessages.fight_surrender)
        else
          if resolved_winning_team
            if npc_fight?
              winner_name = match.arena_participations.find_by(team: resolved_winning_team)&.participant_name
              log_entry("victory", nil, Arena::CombatLogMessages.victory_named(winner_name)) if winner_name.present?
            end
            log_entry("victory", nil, Arena::CombatLogMessages.victory_side(resolved_winning_team))
          else
            log_entry("draw", nil, Arena::CombatLogMessages.draw)
          end
        end
        true
      end

      return false unless ended

      ActiveRecord.after_all_transactions_commit do
        broadcaster.broadcast_match_ended(resolved_winning_team, reason:)
        broadcaster.broadcast_state_refresh(reason: :match_ended)
      end
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
      return failure(I18n.t("game.fight.errors.not_active")) unless match.live?
      return failure(I18n.t("game.fight.errors.not_participating")) unless participant?(character)
      return failure(I18n.t("game.fight.errors.turn_timer_active")) unless match.turn_timed_out?

      participation = match.arena_participations.find_by(character:)
      return failure(I18n.t("game.fight.errors.submit_turn_first")) unless pending_turn_data(participation).present?

      normalized_mode = mode.to_s == "draw" ? "draw" : "victory"
      winning_team = (normalized_mode == "draw") ? nil : participation.team

      description = if normalized_mode == "draw"
        Arena::CombatLogMessages.timeout_draw(character.name)
      else
        Arena::CombatLogMessages.timeout_victory(character.name)
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

      ActiveRecord.after_all_transactions_commit do
        broadcaster.broadcast_timeout_claim_available
        broadcaster.broadcast_state_refresh(reason: :timeout_claim_available)
      end
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

      validation_errors = validate_turn_actions(
        normalized_attacks,
        normalized_blocks,
        normalized_skills,
        actor: character,
        target:
      )
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

    def process_player_turn_submission(
      character,
      target: nil,
      attacks: [],
      blocks: [],
      skills: [],
      expected_turn_number: nil
    )
      participation = match.arena_participations.find_by(character:)
      return failure(I18n.t("game.fight.errors.not_participating")) unless participation

      normalized_attacks = normalize_turn_attacks(attacks)
      normalized_blocks = normalize_turn_blocks(blocks)
      normalized_skills = normalize_turn_skills(skills)

      validation_errors = validate_turn_actions(
        normalized_attacks,
        normalized_blocks,
        normalized_skills,
        actor: character,
        target:
      )
      return failure(validation_errors.join(", ")) if validation_errors.any?

      mana_errors = validate_turn_mana(character, normalized_attacks, normalized_blocks, normalized_skills)
      return failure(mana_errors.join(", ")) if mana_errors.any?

      ap_limit = combat_ap_limit_for(character)
      total_ap = calculate_turn_ap_cost(normalized_attacks, normalized_blocks, normalized_skills, actor: character)
      resolved = false
      match.with_lock do
        match.reload
        participation.reload
        character.reload
        round_number = match.current_turn_number || 1
        expected_round = Integer(expected_turn_number, exception: false)

        return failure(I18n.t("game.fight.errors.not_active")) unless match.live?
        return failure(I18n.t("game.fight.errors.character_defeated")) unless character.current_hp.positive?
        if expected_round && expected_round != round_number
          return failure(I18n.t("game.fight.errors.state_changed"))
        end
        return failure(I18n.t("game.fight.errors.turn_already_submitted")) if pending_turn_current?(participation)

        pending_turn = {
          "turn_number" => round_number,
          "target_participation_id" => target_participation_id(target),
          "attacks" => normalized_attacks.map { |attack| stringify_hash(attack) },
          "blocks" => normalized_blocks.map { |block| stringify_hash(block) },
          "skills" => normalized_skills.map { |skill| stringify_hash(skill) },
          "total_ap" => total_ap,
          "ap_limit" => ap_limit,
          "submitted_at" => Time.current.iso8601
        }

        spend_turn_mana!(character, normalized_attacks, normalized_blocks, normalized_skills)

        participation.metadata ||= {}
        participation.metadata["pending_turn"] = pending_turn
        participation.metadata["current_ap"] = [ap_limit - total_ap, 0].max
        participation.save!

        log_entry("action", character, Arena::CombatLogMessages.turn_submitted(character.name))
        broadcaster.broadcast_ap_update(character, participation.metadata["current_ap"], ap_limit)
        broadcaster.broadcast_system_message(Arena::CombatLogMessages.turn_submitted(character.name))

        resolved = resolve_pending_player_turns! if all_player_turns_ready?
      end

      if resolved
        ActiveRecord.after_all_transactions_commit do
          match.reload
          broadcaster.broadcast_state_refresh(reason: :round_resolved) unless match.completed?
        end
      end

      success(waiting: !resolved, resolved:, total_ap:)
    end

    def process_solo_npc_turn(
      character,
      target: nil,
      attacks: [],
      blocks: [],
      skills: [],
      expected_turn_number: nil
    )
      result = nil

      match.with_lock do
        match.reload
        participation = match.arena_participations.find_by(character:)
        round_number = match.current_turn_number || 1
        expected_round = Integer(expected_turn_number, exception: false)

        if !match.live?
          result = failure(I18n.t("game.fight.errors.not_active"))
        elsif participation.nil?
          result = failure(I18n.t("game.fight.errors.not_participating"))
        elsif expected_round && expected_round != round_number
          result = failure(I18n.t("game.fight.errors.state_changed"))
        elsif participation.metadata.to_h["last_resolved_turn_number"].to_i >= round_number
          result = failure(I18n.t("game.fight.errors.turn_already_resolved"))
        else
          ap_cost = calculate_ap_cost(:turn, {attacks:, blocks:, skills:}, actor: character)
          current_ap = get_character_ap(character)

          if current_ap < ap_cost
            result = failure(I18n.t("game.fight.errors.not_enough_ap", need: ap_cost, have: current_ap))
          else
            turn_result = process_turn(character, target:, attacks:, blocks:, skills:)
            if turn_result.success?
              deduct_ap(character, ap_cost)
              broadcaster.broadcast_ap_update(character, get_character_ap(character), combat_ap_limit_for(character))

              if npc_response_required_for?(character) && !should_end?
                process_npc_turn_after_delay(
                  character,
                  only_participation_ids: counter_npc_participation_ids(target)
                )
              end

              participation.reload
              participation.update!(metadata: participation.metadata.to_h.merge(
                "last_resolved_turn_number" => round_number
              ))

              if match.reload.live?
                clear_blocking_state(character.reload)
                npc_turn_participations.each { |npc| clear_npc_blocking_state(npc) }
                match.update!(
                  current_turn_started_at: Time.current,
                  current_turn_number: round_number + 1,
                  current_turn_team: nil
                )
                # Restart the 5-minute inactivity clock after every answered turn.
                match.schedule_timeout_check
                reset_ap(character)
                broadcaster.broadcast_ap_update(character, combat_ap_limit_for(character), combat_ap_limit_for(character))
              end

              result = success(**turn_result.data, resolved: true, round_number:)
            else
              result = turn_result
            end
          end
        end
      end

      if result&.success?
        ActiveRecord.after_all_transactions_commit do
          broadcaster.broadcast_state_refresh(reason: :round_resolved) if match.reload.live?
        end
      end

      result
    end

    def resolve_pending_player_turns!
      participants = live_player_participations
      pending_turns = participants.index_with { |participation| pending_turn_data(participation) }
      round_number = match.current_turn_number || 1

      broadcaster.broadcast_system_message(Arena::CombatLogMessages.resolving_round(round_number))

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
      return failure(I18n.t("game.fight.errors.invalid_attack_type", type: attack_type)) if Game::Combat::ActionCatalog.attack_config(attack_type).blank?
      return failure(I18n.t("game.fight.errors.invalid_attack_zone", zone: body_part)) unless BODY_PARTS.include?(body_part.to_s)

      # Find target - could be Character or NPC participation
      target_participation = find_target_participation(attacker, target)
      return failure(I18n.t("game.fight.errors.no_valid_target")) unless target_participation

      # Check if target is NPC or player
      if target_participation.npc?
        process_attack_on_npc(attacker, target_participation, attack_type:, body_part:)
      else
        process_attack_on_player(attacker, target_participation.character, attack_type:, body_part:)
      end
    end

    def process_attack_on_player(attacker, target, attack_type: :simple, body_part: "torso")
      return failure(I18n.t("game.fight.errors.cannot_attack_ally")) if same_team?(attacker, target)
      return failure(I18n.t("game.fight.errors.target_dead")) if target.current_hp <= 0

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
        log_entry("miss", attacker, Arena::CombatLogMessages.missed(attacker.name, target.name, body_part))
        broadcaster.broadcast_combat_action(attacker, "miss", target, 0, body_part:, miss: true)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", target, Arena::CombatLogMessages.dodged(target.name, attacker.name, body_part))
        broadcaster.broadcast_combat_action(attacker, "dodge", target, 0, body_part:, dodge: true)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_blocking_state(target)
        log_entry("block", target, Arena::CombatLogMessages.blocked(target.name, attacker.name, body_part))
        broadcaster.broadcast_combat_action(attacker, "blocked", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_blocking_state(target)
        log_entry("block_failed", target, Arena::CombatLogMessages.block_failed(target.name, attacker.name, body_part))
      end

      # Neverlands logs the rolled hit even when it exceeds the remaining HP,
      # while fight statistics count only HP actually removed.
      previous_hp = target.current_hp
      target.current_hp = [previous_hp - damage, 0].max
      applied_damage = previous_hp - target.current_hp
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

      track_damage!(attacker_participation, target_participation, applied_damage, critical:, body_part:)

      success(**attack_result_payload(resolution, attack_type:, body_part:, target_hp: target.current_hp))
    end

    def process_attack_on_npc(attacker, npc_participation, attack_type: :simple, body_part: "torso")
      npc = npc_participation.npc_template
      attacker_participation = match.arena_participations.find_by(character: attacker)
      return failure(I18n.t("game.fight.errors.cannot_attack_ally")) if attacker_participation&.team == npc_participation.team
      return failure(I18n.t("game.fight.errors.target_dead")) if npc_participation.current_hp <= 0

      resolution = resolve_physical_attack(
        attacker_participation:,
        defender_participation: npc_participation,
        action_key: attack_type,
        body_part:,
        block: blocking_data_for_npc(npc_participation, body_part)
      )

      case resolution[:outcome]
      when :miss
        log_entry("miss", attacker, Arena::CombatLogMessages.missed(attacker.name, npc.name, body_part))
        broadcast_npc_action(npc, "miss", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", npc_participation, Arena::CombatLogMessages.dodged(npc.name, attacker.name, body_part))
        broadcast_npc_action(npc, "dodge", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_npc_blocking_state(npc_participation)
        log_entry("block", npc_participation, Arena::CombatLogMessages.blocked(npc.name, attacker.name, body_part))
        broadcast_npc_action(npc, "blocked", nil, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_npc_blocking_state(npc_participation)
        log_entry("block_failed", npc_participation, Arena::CombatLogMessages.block_failed(npc.name, attacker.name, body_part))
      end

      # Preserve raw overkill in the log, but count only removed HP in the
      # result statistics.
      previous_hp = npc_participation.current_hp
      new_hp = [previous_hp - damage, 0].max
      applied_damage = previous_hp - new_hp
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

      track_damage!(attacker_participation, npc_participation, applied_damage, critical:, body_part:)

      success(**attack_result_payload(resolution, attack_type:, body_part:, target_hp: new_hp))
    end

    def find_target_participation(attacker, target)
      attacker_team = match.arena_participations.find_by(character: attacker)&.team

      if target.is_a?(Character)
        match.arena_participations.find_by(character: target)
      elsif target.is_a?(ArenaParticipation)
        match.arena_participations.find_by(id: target.id)
      else
        # Find the lowest-HP living opponent. Defeated group members must not
        # absorb the next turn after the Neverlands target handoff.
        match.arena_participations
          .where.not(team: attacker_team)
          .select { |participation| participation_hp(participation).positive? }
          .min_by { |participation| participation_hp(participation) }
      end
    end

    def broadcast_npc_vitals_update(npc_participation)
      npc = npc_participation.npc_template
      broadcaster.broadcast_event(
        {
          type: "npc_vitals_update",
          npc_name: npc.name,
          npc_id: npc.id,
          participation_id: npc_participation.id,
          current_hp: npc_participation.current_hp,
          max_hp: npc_participation.max_hp,
          hp_percent: (npc_participation.current_hp.to_f / npc_participation.max_hp * 100).round
        }
      )
    end

    def handle_npc_defeat(npc_participation, defeated_by: nil)
      npc = npc_participation.npc_template
      npc_participation.update!(result: "defeat", ended_at: Time.current)
      log_entry("defeat", npc_participation, Arena::CombatLogMessages.defeated(npc.name))
      award_npc_loot!(npc_participation, defeated_by) if defeated_by
      mark_world_tile_npc_defeated!(defeated_by) if defeated_by && all_npcs_defeated?

      broadcaster.broadcast_event(
        {
          type: "npc_defeated",
          npc_name: npc.name,
          npc_id: npc.id
        }
      )
    end

    def mark_world_tile_npc_defeated!(defeated_by)
      return unless match.metadata&.dig("source") == "world_npc"
      return if match.metadata&.dig("personal_instance") == true
      return if match.metadata&.dig("repeatable_encounter_source") == true

      tile_npc = TileNpc.find_by(id: match.metadata["tile_npc_id"])
      tile_npc&.defeat!(defeated_by)
    end

    # Personal ambush NPCs must leave the cell when the fight ends (win or lose),
    # otherwise yellow nameplates and agro chrome stick on the outdoor map.
    def cleanup_personal_world_npc!
      meta = match.metadata.to_h
      return unless meta["personal_instance"] == true || meta["source"] == "world_live_ambush"

      tile_npc = TileNpc.find_by(id: meta["tile_npc_id"])
      return unless tile_npc

      ambush = tile_npc.npc_key.to_s.start_with?("ashen_ambush_") ||
        tile_npc.metadata.to_h["source"].to_s == "world_live_ambush" ||
        tile_npc.metadata.to_h["ambush_label"].present?

      if ambush
        tile_npc.destroy!
      elsif tile_npc.personal_instance?
        tile_npc.update!(
          defeated_at: Time.current,
          current_hp: 0,
          respawns_at: nil,
          metadata: tile_npc.metadata.to_h.merge("active" => false, "ambush_cleared_at" => Time.current.iso8601)
        )
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def all_npcs_defeated?
      match.arena_participations.npcs.all? { |participation| participation.current_hp <= 0 }
    end

    def award_npc_loot!(npc_participation, defeated_by)
      npc = npc_participation.npc_template
      result = loot_awarder_class.new(
        match:,
        npc_participation:,
        character: defeated_by,
        rng:,
        event_publisher:
      ).call
      return [] if result.already_processed?

      result.failures.each do |failure|
        log_entry("loot", defeated_by, Arena::CombatLogMessages.loot_failed(defeated_by.name, npc.name, failure.message))
      end

      if result.awards.empty? && result.failures.empty?
        log_entry("loot", defeated_by, Arena::CombatLogMessages.loot_nothing(defeated_by.name, npc.name))
      elsif result.awards.any?
        found = result.awards.map(&:description).join(", ")
        log_entry("loot", defeated_by, Arena::CombatLogMessages.loot_found(defeated_by.name, npc.name, found))
      end

      result.awards
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
      log_entry("action", character, Arena::CombatLogMessages.defensive_stance(character.name, parts_str))
      broadcaster.broadcast_combat_action(character, "defend", nil, 0, block_parts:)

      success(defending: true, block_parts:)
    end

    def process_turn_skill(character, skill, target)
      key = skill[:key].to_s
      if Game::Combat::ActionCatalog.attack_config(key).present?
        return process_attack(
          character,
          target,
          attack_type: key,
          body_part: (skill[:body_part].presence || "torso")
        )
      end

      config = Game::Combat::ActionCatalog.magic_config(key)
      return failure(I18n.t("game.fight.errors.magic_not_found", key: key)) if config.blank?

      failure(I18n.t("game.fight.errors.magic_resolver_required", name: config["name"] || key))
    end

    def find_target(target_id)
      return nil unless target_id

      match.arena_participations.includes(:character).find_by(character_id: target_id)&.character
    end

    # Neverlands surrender defeats the conceding participant. The shared side
    # only loses when every participant on that side has been defeated or has
    # surrendered, so the same transition works for 1x1, 1xMany, and ManyxMany
    # PvP/PvE fights.
    def process_surrender(character)
      result = nil

      match.with_lock do
        match.reload
        participation = match.arena_participations.find_by(character:)

        result = if !match.live?
          failure(I18n.t("game.fight.errors.not_active"))
        elsif participation.nil?
          failure(I18n.t("game.fight.errors.not_participating"))
        elsif participation.result == "defeat" || character.reload.current_hp <= 0
          failure(I18n.t("game.fight.errors.character_defeated"))
        else
          character.update!(current_hp: 0, last_combat_at: Time.current)
          participation.update!(
            result: :defeat,
            ended_at: Time.current,
            metadata: participation.metadata.to_h.merge("surrendered_at" => Time.current.iso8601)
          )

          log_entry("defeat", character, Arena::CombatLogMessages.surrendered(character.name))
          broadcaster.broadcast_vitals_update(character)

          side_defeated = should_end?
          end_match(determine_winner, reason: :forfeit) if side_defeated
          success(surrendered: true, match_ended: side_defeated)
        end
      end

      result
    end

    def calculate_base_damage(character)
      # Prefer CombatResolver for live fights; this helper mirrors base_hit mid-band.
      power = [character.attack_power.to_f, 1.0].max
      ((power * Arena::CombatResolver::BASE_HIT_MIN_FACTOR) +
        (power * Arena::CombatResolver::BASE_HIT_MAX_FACTOR)) / 2.0
    end

    def calculate_defense(character)
      character.defense.to_i
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

    def track_damage!(attacker_participation, defender_participation, damage, critical: false, body_part: nil)
      return if damage.to_i <= 0

      if attacker_participation
        attacker_participation.reload
        attacker_participation.metadata ||= {}
        attacker_participation.metadata["damage_dealt"] = attacker_participation.metadata["damage_dealt"].to_i + damage.to_i
        attacker_participation.metadata["damage_hits"] = attacker_participation.metadata["damage_hits"].to_i + 1
        attacker_participation.save!
      end

      if defender_participation
        defender_participation.reload
        defender_participation.metadata ||= {}
        defender_participation.metadata["damage_taken"] = defender_participation.metadata["damage_taken"].to_i + damage.to_i
        if critical
          defender_participation.metadata["critical_hits_taken"] =
            defender_participation.metadata["critical_hits_taken"].to_i + 1
          defender_participation.metadata["critical_damage_taken"] =
            defender_participation.metadata["critical_damage_taken"].to_i + damage.to_i
        end
        if body_part.to_s == "head"
          defender_participation.metadata["head_hits_taken"] =
            defender_participation.metadata["head_hits_taken"].to_i + 1
        end
        defender_participation.save!
      end
    end

    def physical_hit_log(attacker_name, target_name, attack_type, body_part, damage, current_hp, max_hp, critical: false)
      Arena::CombatLogMessages.physical_hit(
        attacker_name, target_name, attack_type, body_part, damage, current_hp, max_hp, critical:
      )
    end

    def find_default_target(attacker)
      attacker_team = match.arena_participations.find_by(character: attacker)&.team

      participation = match.arena_participations
        .where.not(team: attacker_team)
        .includes(:character)
        .select { |entry| participation_hp(entry).positive? }
        .min_by { |entry| participation_hp(entry) }

      participation&.npc? ? participation : participation&.character
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
      log_entry("defeat", character, Arena::CombatLogMessages.defeated_short)
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

    def finalize_rewards!(winning_team)
      return if match.metadata.to_h["rewards_processed_at"].present?

      xp_result = if npc_fight?
        Arena::NpcExperienceAwarder.new(match:, winning_team:).call
      end
      wear_results = Arena::EquipmentWearResolver.new(match:, rng:).call
      injury_results = Game::Combat::InjuryResolver.new(match:, rng:).call
      record_fight_record!(winning_team)
      record_solo_npc_victory!(winning_team) if npc_fight?
      advance_dungeon_pack!(winning_team) if npc_fight?
      advance_catalog_instance!(winning_team) if npc_fight?
      Game::World::FortressSiegeBattle.record_victory!(match:, winning_team:)

      if xp_result&.party_awards.present?
        xp_result.party_awards.each do |award|
          winner = Character.find(award.fetch(:character_id))
          log_entry("system", winner, Arena::CombatLogMessages.xp_gain(winner.name, award.fetch(:experience_awarded)))
        end
      elsif xp_result&.experience_awarded.to_i.positive?
        winner = Character.find(xp_result.character_id)
        log_entry("system", winner, Arena::CombatLogMessages.xp_gain(winner.name, xp_result.experience_awarded))
      end

      wear_results.each do |result|
        next if result.item_ids.empty?

        character = Character.find(result.character_id)
        log_entry("system", character, Arena::CombatLogMessages.durability_loss(character.name))
      end

      publish_fight_finished_events!(xp_result, winning_team)

      reward_metadata = {
        "experience" => xp_result && {
          "character_id" => xp_result.character_id,
          "amount" => xp_result.experience_awarded,
          "levels_gained" => xp_result.levels_gained,
          "skipped_reason" => xp_result.skipped_reason
        },
        "equipment_wear" => wear_results.map do |result|
          {
            "character_id" => result.character_id,
            "chance_percent" => result.chance_percent,
            "item_ids" => result.item_ids
          }
        end,
        "ashen_injuries" => injury_results.map { |result| {"severity" => result.severity} }
      }.compact

      match.update!(metadata: match.metadata.to_h.merge(
        "rewards_processed_at" => Time.current.iso8601,
        "rewards" => reward_metadata
      ))
    end

    def publish_fight_finished_events!(xp_result, winning_team)
      match.arena_participations.players.includes(:character, :user).each do |participation|
        recipient = participation.user || participation.character&.user
        next unless recipient

        experience = if xp_result&.character_id == participation.character_id
          xp_result.experience_awarded
        else
          0
        end

        event_publisher.fight_finished!(
          recipient:,
          experience:,
          event_key: "arena-match:#{match.id}:participation:#{participation.id}:finished",
          payload: {
            arena_match_id: match.id,
            character_id: participation.character_id,
            participation_id: participation.id,
            result: participation.result,
            winning_team:,
            source: match.metadata.to_h["source"],
            damage_dealt: participation.metadata.to_h["damage_dealt"].to_i,
            damage_taken: participation.metadata.to_h["damage_taken"].to_i
          }.compact
        )
      end
    end

    def record_fight_record!(winning_team)
      match.arena_participations.players.includes(:character).find_each do |participation|
        character = participation.character
        next unless character

        character.with_lock do
          character.reload
          meta = character.metadata.to_h
          if npc_fight?
            if participation.result.to_s == "victory"
              meta["npc_wins"] = meta["npc_wins"].to_i + 1
              Game::WorldEvents::TournamentScore.record_chaos_win!(character:)
            elsif participation.result.to_s == "defeat"
              meta["npc_losses"] = meta["npc_losses"].to_i + 1
            end
          else
            if participation.result.to_s == "victory"
              meta["player_wins"] = meta["player_wins"].to_i + 1
              Game::WorldEvents::TournamentScore.record_chaos_win!(character:)
            elsif participation.result.to_s == "defeat"
              meta["player_losses"] = meta["player_losses"].to_i + 1
            end
          end
          character.update!(metadata: meta)
        end
      end
    end

    def record_solo_npc_victory!(winning_team)
      return if winning_team.blank?

      winners = match.arena_participations.players.where(team: winning_team).includes(:character).to_a
      return unless winners.one?

      winner = winners.first.character

      defeated_keys = match.arena_participations.npcs
        .where.not(team: winning_team)
        .includes(:npc_template)
        .select(&:defeat?)
        .filter_map { |participation| participation.npc_template&.npc_key.presence }
      defeated_keys.each do |npc_key|
        Game::Quests::Journal.new(character: winner).record_npc_kill!(npc_key:)
        Game::Activity::Tracker.new(character: winner).record!(kind: "kill_npc", amount: 1, meta: {"npc_key" => npc_key})
      end
      Game::Activity::Tracker.new(character: winner).record!(kind: "arena_fight", amount: 1)
      Game::Pets::HuntAssist.after_victory!(winner)
      family = winner.equipment_weapon_family
      Game::Skills::UseTrainer.new(character: winner).train_from_combat_hit!(weapon_family: family)
    end

    def advance_dungeon_pack!(winning_team)
      return if winning_team.blank?
      return unless match.metadata.to_h["instance_kind"].to_s == "dungeon_pack"

      pack_key = match.metadata.to_h["pack_key"].to_s
      return if pack_key.blank?

      winners = match.arena_participations.players.where(team: winning_team).includes(:character).to_a
      return if winners.empty?

      if match.metadata.to_h["party_character_ids"].present?
        Game::Instances::PackLaunch.advance_party_after_victory!(match:)
      elsif winners.one?
        Game::Instances::PackLaunch.advance_after_victory!(
          character: winners.first.character,
          pack_key:
        )
      end
    end

    def advance_catalog_instance!(winning_team)
      return if winning_team.blank?

      meta = match.metadata.to_h
      return unless meta["catalog_run"]
      return unless meta["instance_kind"].to_s.in?(%w[dungeon raid])

      winners = match.arena_participations.players.where(team: winning_team).includes(:character).to_a
      return unless winners.one?

      character = winners.first.character
      catalog = if meta["instance_kind"].to_s == "raid"
        Array(Game::Catalog::AshenVeilFiles.raids["raids"]).find { |row| row["id"].to_s == meta["instance_id"].to_s }
      else
        Array(Game::Catalog::AshenVeilFiles.dungeons["dungeons"]).find { |row| row["id"].to_s == meta["instance_id"].to_s }
      end

      advance = Game::Instances::CatalogProgress.advance_after_victory!(
        character:,
        kind: meta["instance_kind"],
        id: meta["instance_id"],
        rooms_total: meta["rooms_total"].to_i,
        catalog:
      )
      match.update!(
        metadata: meta.merge(
          "catalog_advance" => {
            "cleared" => advance.cleared,
            "next_room" => advance.next_room,
            "status" => advance.status,
            "message" => advance.message
          },
          "continue_after_win" => !advance.cleared
        )
      )
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

    def validate_turn_actions(attacks, blocks, skills, actor: nil, target: nil)
      errors = []

      errors << I18n.t("game.fight.turn_need_action") if attacks.empty? && blocks.empty? && skills.empty?
      unless valid_neverlands_turn_shape?(attacks, blocks, skills)
        errors << I18n.t("game.fight.turn_need_valid_shape")
      end
      errors << I18n.t("game.fight.turn_one_block") if blocks.size > 1
      errors << I18n.t("game.fight.turn_max_attacks") if attacks.size > 4
      attack_parts = attacks.map { |attack| attack[:body_part] }
      if attack_parts.include?("head") && attack_parts.include?("legs")
        errors << I18n.t("game.fight.turn_head_legs")
      end
      target_error = validate_turn_target(actor, target) if actor.present? && attacks.any?
      errors << target_error if target_error.present?

      attacks.each_with_index do |attack, index|
        unless BODY_PARTS.include?(attack[:body_part])
          errors << I18n.t("game.fight.turn_invalid_attack_zone", index: index + 1, zone: attack[:body_part])
        end

        if Game::Combat::ActionCatalog.attack_config(attack[:action_key]).blank?
          errors << I18n.t("game.fight.turn_invalid_attack_type", index: index + 1, type: attack[:action_key])
        elsif actor.present? && !Game::Combat::ActionCatalog.attack_allowed_for_profile?(
          attack[:action_key],
          combat_profile_for(actor)
        )
          errors << I18n.t("game.fight.turn_attack_unavailable", index: index + 1)
        end
      end

      blocks.each_with_index do |block, index|
        if block[:body_parts].blank?
          errors << I18n.t("game.fight.turn_block_empty", index: index + 1)
          next
        end

        block[:body_parts].each do |part|
          errors << I18n.t("game.fight.turn_invalid_block_zone", index: index + 1, zone: part) unless BODY_PARTS.include?(part)
        end

        config = Game::Combat::ActionCatalog.block_config(block[:action_key])
        if config.blank?
          errors << I18n.t("game.fight.turn_invalid_block_type", index: index + 1, type: block[:action_key])
          next
        end

        if actor.present? && !Game::Combat::ActionCatalog.block_allowed_for_profile?(
          block[:action_key],
          combat_profile_for(actor)
        )
          errors << I18n.t("game.fight.turn_block_unavailable", index: index + 1)
        end

        configured_parts = config["body_parts"] || [config["body_part"]].compact
        if Game::Combat::ActionCatalog.canonical_parts(configured_parts) != block[:body_parts]
          errors << I18n.t("game.fight.turn_block_zones_mismatch", index: index + 1, type: block[:action_key])
        end
      end

      skills.each_with_index do |skill, index|
        unless Game::Combat::ActionCatalog.magic_config(skill[:key]).present?
          errors << I18n.t("game.fight.turn_invalid_magic", index: index + 1, key: skill[:key])
        end
      end

      total_ap = calculate_turn_ap_cost(attacks, blocks, skills, actor:)
      ap_limit = actor.present? ? combat_ap_limit_for(actor) : AP_PER_TURN
      errors << I18n.t("game.fight.turn_ap_exceeded", used: total_ap, limit: ap_limit) if total_ap > ap_limit

      errors
    end

    def validate_turn_target(actor, target)
      actor_participation = participation_from(actor)
      target_participation = participation_from(target)
      return I18n.t("game.fight.errors.no_valid_target") unless target_participation&.arena_match_id == match.id
      return I18n.t("game.fight.errors.cannot_attack_ally") if target_participation.team == actor_participation&.team
      return I18n.t("game.fight.errors.target_dead") unless participation_hp(target_participation).positive?

      nil
    end

    def valid_neverlands_turn_shape?(attacks, blocks, skills)
      return true if attacks.size > 1
      return true if attacks.any? && blocks.any?
      return true if attacks.any? && skills.any?
      return true if blocks.any? && skills.any?

      false
    end

    def validate_turn_mana(character, attacks, blocks, skills)
      total_mana = calculate_turn_mana_cost(attacks, blocks, skills)
      errors = []

      if total_mana > character.current_mp.to_i
        errors << I18n.t("game.fight.turn_not_enough_mp", need: total_mana, have: character.current_mp.to_i)
      end

      magic_limit = combat_profile_for(character).fetch("max_magic_mana", character.max_mp.to_i).to_i
      expensive_actions = [
        *attacks.filter_map { |attack| attack_mana_cost(attack[:action_key]) },
        *blocks.filter_map { |block| block_mana_cost(block) },
        *skills.filter_map { |skill| magic_action_mana_cost(skill[:key]) }
      ].select { |cost| cost.to_i > magic_limit }
      if expensive_actions.any?
        errors << I18n.t("game.fight.turn_magic_mana_limit", used: expensive_actions.max, limit: magic_limit)
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

    def schedule_timeout_check_safely
      match.schedule_timeout_check
    rescue StandardError => error
      logger.error(
        "[Arena::CombatProcessor] timeout_enqueue_failed " \
        "match_id=#{match.id} error=#{error.class}"
      )
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
      if target_participation &&
          target_participation.team != participation.team &&
          participation_hp(target_participation).positive?
        return target_participation
      end

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
    def process_npc_turn_after_delay(character, only_participation_ids: nil)
      team = match.arena_participations.find_by(character:)&.team
      process_npc_turn(opposing_team: team, only_participation_ids:)
    end

    # Wilderness packs used to have every bot strike after one player hit.
    # Counter only the focused target; if missing, the first alive opposing NPC.
    def counter_npc_participation_ids(target)
      if target.is_a?(ArenaParticipation) && target.npc? && target.current_hp.to_i.positive?
        return [target.id]
      end

      npc = match.arena_participations.npcs.detect { |row| row.current_hp.to_i.positive? }
      npc ? [npc.id] : []
    end

    def process_single_npc_turn(npc_participation)
      npc = npc_participation.npc_template
      return unless npc && npc_participation.current_hp.positive?

      ai = Arena::NpcCombatAi.new(
        npc_template: npc,
        participation: npc_participation,
        match:,
        rng:
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

      return failure(I18n.t("game.fight.errors.no_valid_target")) unless target
      return failure(I18n.t("game.fight.errors.target_dead")) if target.current_hp <= 0

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
        log_entry("miss", npc_participation, Arena::CombatLogMessages.missed(npc.name, target.name, body_part))
        broadcast_npc_action(npc, "miss", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :dodge
        log_entry("dodge", target, Arena::CombatLogMessages.dodged(target.name, npc.name, body_part))
        broadcast_npc_action(npc, "dodge", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      when :blocked
        clear_blocking_state(target)
        log_entry("block", target, Arena::CombatLogMessages.blocked(target.name, npc.name, body_part))
        broadcast_npc_action(npc, "blocked", target, 0, body_part:)
        return success(**attack_result_payload(resolution, attack_type:, body_part:))
      end

      damage = resolution[:damage]
      critical = resolution[:critical]
      if resolution[:block_attempted]
        clear_blocking_state(target)
        log_entry("block_failed", target, Arena::CombatLogMessages.block_failed(target.name, npc.name, body_part))
      end

      # Apply damage to player while keeping result statistics bounded by the
      # HP that was actually removed.
      previous_hp = target.current_hp
      target.current_hp = [previous_hp - damage, 0].max
      applied_damage = previous_hp - target.current_hp
      target.last_combat_at = Time.current
      target.save!

      # Log and broadcast
      log_type = critical ? "critical" : "damage"
      log_entry(log_type, npc_participation, Arena::CombatLogMessages.npc_attack(npc.name, target.name, body_part, damage, critical: critical))

      broadcaster.broadcast_vitals_update(target)
      broadcast_npc_action(npc, "attack", target, damage, critical: critical, body_part: body_part)
      track_damage!(npc_participation, target_participation, applied_damage, critical:, body_part:)

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

      log_entry("action", npc_participation, Arena::CombatLogMessages.defensive_stance_simple(npc.name))
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
      broadcaster.broadcast_event(
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
