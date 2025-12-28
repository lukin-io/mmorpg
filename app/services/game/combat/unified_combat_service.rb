# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Unified combat service that works for PvE, PvP, and Arena battles.
    # Provides a consistent interface for all combat types while delegating
    # to the appropriate resolvers and services.
    #
    # Inputs:
    #   - battle: Battle record
    #   - rng: Random instance for deterministic results (optional)
    #
    # Usage:
    #   service = Game::Combat::UnifiedCombatService.new(battle)
    #   result = service.submit_turn(participant, attacks: [...], blocks: [...])
    #   result = service.resolve_round!
    #
    class UnifiedCombatService
      attr_reader :battle, :rng

      def initialize(battle, rng: nil)
        @battle = battle
        @rng = rng || Random.new(battle.rng_seed || SecureRandom.random_number(2**31))
        @config = load_config
      end

      # Submit turn actions for a participant
      #
      # @param participant [BattleParticipant] the participant submitting
      # @param attacks [Array<Hash>] attack actions
      # @param blocks [Array<Hash>] block actions
      # @param skills [Array<Hash>] skill/magic actions
      # @return [Result] submission result
      def submit_turn(participant, attacks: [], blocks: [], skills: [])
        return Result.failure("Battle is not active") unless battle.active?
        return Result.failure("Not your turn") unless can_act?(participant)

        # Validate actions
        validator = ActionValidator.new(participant, @config)
        validation = validator.validate(attacks: attacks, blocks: blocks, skills: skills)

        unless validation.valid?
          return Result.failure(validation.errors.first)
        end

        # Submit the turn
        participant.submit_turn!(
          attacks: attacks,
          blocks: blocks,
          skills: skills,
          ap_used: validation.total_ap
        )

        # Handle NPC participants
        generate_npc_turns

        # Auto-resolve if all ready
        if battle.simultaneous? && battle.all_participants_ready?
          resolve_result = resolve_round!
          return Result.success(
            turn_submitted: true,
            round_resolved: true,
            resolution: resolve_result
          )
        end

        Result.success(turn_submitted: true, round_resolved: false)
      end

      # Resolve the current round
      #
      # @return [Result] resolution result with log entries and state changes
      def resolve_round!
        return Result.failure("Battle is not active") unless battle.active?

        resolver = TurnResolver.new(battle, rng: @rng, config: @config)
        result = resolver.resolve!

        # Persist combat log entries
        persist_log_entries(result.log_entries)

        # Broadcast results
        broadcast_resolution(result)

        if result.battle_ended
          handle_battle_end(result.winner_team)
        elsif battle.turn_timeout_seconds.positive?
          # Start timer for next round
          battle.start_turn_timer!
        end

        Result.success(
          log_entries: result.log_entries,
          hp_changes: result.hp_changes,
          mp_changes: result.mp_changes,
          battle_ended: result.battle_ended,
          winner_team: result.winner_team
        )
      end

      # Start a new battle
      #
      # @param initiator [Character] the character starting the battle
      # @param opponent [Character, NpcTemplate] the opponent
      # @param zone [Zone] optional zone context
      # @param battle_type [Symbol] :pve, :pvp, or :arena
      # @return [Result] with created battle
      def self.start_battle(initiator:, opponent:, zone: nil, battle_type: :pve)
        ActiveRecord::Base.transaction do
          seed = SecureRandom.random_number(2**31)

          battle = Battle.create!(
            initiator: initiator,
            zone: zone,
            battle_type: battle_type,
            status: :active,
            turn_number: 1,
            round_number: 1,
            rng_seed: seed,
            combat_mode: "simultaneous"
          )

          # Create initiator participant
          initiator_participant = battle.battle_participants.create!(
            character: initiator,
            team: "alpha",
            role: "attacker",
            initiative: calculate_initiative(initiator),
            hp_remaining: initiator.current_hp,
            current_hp: initiator.current_hp,
            max_hp: initiator.max_hp,
            current_mp: initiator.current_mp || 0,
            max_mp: initiator.max_mp || 0,
            participant_type: "player",
            is_alive: true
          )

          # Create opponent participant
          if opponent.is_a?(Character)
            opponent_participant = battle.battle_participants.create!(
              character: opponent,
              team: "beta",
              role: "defender",
              initiative: calculate_initiative(opponent),
              hp_remaining: opponent.current_hp,
              current_hp: opponent.current_hp,
              max_hp: opponent.max_hp,
              current_mp: opponent.current_mp || 0,
              max_mp: opponent.max_mp || 0,
              participant_type: "player",
              is_alive: true
            )
          else
            # NPC opponent
            npc_hp = opponent.health || opponent.metadata&.dig("max_hp") || 50
            npc_mp = opponent.metadata&.dig("max_mp") || 0
            opponent_participant = battle.battle_participants.create!(
              npc_template: opponent,
              team: "beta",
              role: "defender",
              initiative: calculate_npc_initiative(opponent),
              hp_remaining: npc_hp,
              current_hp: npc_hp,
              max_hp: npc_hp,
              current_mp: npc_mp,
              max_mp: npc_mp,
              participant_type: "npc",
              is_alive: true
            )
          end

          # Start turn timer
          battle.start_turn_timer!

          Result.success(
            battle: battle,
            initiator_participant: initiator_participant,
            opponent_participant: opponent_participant
          )
        end
      rescue ActiveRecord::RecordInvalid => e
        Result.failure("Failed to create battle: #{e.message}")
      end

      # Flee from combat
      #
      # @param participant [BattleParticipant] fleeing participant
      # @return [Result] flee result
      def flee(participant)
        return Result.failure("Battle is not active") unless battle.active?
        return Result.failure("Cannot flee while dead") unless participant.can_act?

        # Calculate flee chance
        entity = participant.entity
        agility = extract_stat(entity, :agility)
        flee_chance = 30 + (agility * 0.5)

        roll = @rng.rand(100)
        fled = roll < flee_chance

        if fled
          # Successful flee
          opponent_team = (participant.team == "alpha") ? "beta" : "alpha"
          battle.update!(status: :completed, winning_team: opponent_team, ended_at: Time.current)

          broadcast_flee(participant, true)

          Result.success(fled: true, message: "Successfully fled from combat!")
        else
          # Failed flee - lose turn
          participant.clear_turn!
          broadcast_flee(participant, false)

          # If opponent is NPC, resolve their turn
          generate_npc_turns
          resolve_round! if battle.all_participants_ready?

          Result.success(fled: false, message: "Failed to flee! You lose your turn.")
        end
      end

      # Surrender the battle
      #
      # @param participant [BattleParticipant] surrendering participant
      # @return [Result]
      def surrender(participant)
        return Result.failure("Battle is not active") unless battle.active?

        participant.update!(is_alive: false, current_hp: 0)

        opponent_team = (participant.team == "alpha") ? "beta" : "alpha"
        battle.update!(status: :completed, winning_team: opponent_team, ended_at: Time.current)

        broadcast_surrender(participant)

        Result.success(surrendered: true)
      end

      private

      def load_config
        config_path = Rails.root.join("config/gameplay/combat_actions.yml")
        File.exist?(config_path) ? YAML.load_file(config_path) : {}
      end

      def can_act?(participant)
        participant.is_alive && participant.current_hp.to_i > 0 && !participant.stunned?
      end

      def generate_npc_turns
        battle.battle_participants.where(participant_type: "npc").alive.each do |npc_participant|
          next if npc_participant.turn_submitted?

          resolver = TurnResolver.new(battle, rng: @rng, config: @config)
          actions = resolver.generate_npc_actions(npc_participant)

          if actions
            npc_participant.submit_turn!(
              attacks: actions[:attacks],
              blocks: actions[:blocks],
              skills: actions[:skills],
              ap_used: 0
            )
          end
        end
      end

      def persist_log_entries(log_entries)
        log_entries.each do |entry|
          battle.combat_log_entries.create!(
            round_number: battle.round_number || 1,
            sequence: battle.next_sequence_for(battle.round_number || 1),
            event_type: entry[:type].to_s,
            message: entry[:message],
            actor_id: entry[:actor_id],
            actor_name: entry[:actor_name],
            metadata: entry[:data]
          )
        end
      end

      def broadcast_resolution(result)
        participants_data = battle.battle_participants.map do |p|
          [p.id, {
            current_hp: p.current_hp,
            max_hp: p.max_hp,
            current_mp: p.current_mp,
            max_mp: p.max_mp,
            is_alive: p.is_alive
          }]
        end.to_h

        ActionCable.server.broadcast(
          battle.broadcast_channel,
          {
            type: "round_complete",
            round: battle.round_number,
            combat_log: result.log_entries,
            participants: participants_data,
            timer_end_at: battle.turn_timer_ends_at&.iso8601,
            battle_ended: result.battle_ended,
            winner_team: result.winner_team
          }
        )
      end

      def handle_battle_end(winner_team)
        # Award rewards, update stats, etc.
        battle.battle_participants.each do |participant|
          next unless participant.character

          if participant.team == winner_team
            # Victory rewards
            xp = calculate_xp_reward(participant)
            calculate_gold_reward(participant)

            participant.character.update!(
              experience: participant.character.experience.to_i + xp
            )
          end
        end

        broadcast_battle_end(winner_team)
      end

      def broadcast_battle_end(winner_team)
        ActionCable.server.broadcast(
          battle.broadcast_channel,
          {
            type: "combat_ended",
            winner_team: winner_team,
            xp_gained: calculate_xp_reward(nil),
            gold_gained: calculate_gold_reward(nil)
          }
        )
      end

      def broadcast_flee(participant, success)
        ActionCable.server.broadcast(
          battle.broadcast_channel,
          {
            type: "flee_attempt",
            participant_id: participant.id,
            participant_name: participant.combatant_name,
            success: success
          }
        )
      end

      def broadcast_surrender(participant)
        ActionCable.server.broadcast(
          battle.broadcast_channel,
          {
            type: "surrender",
            participant_id: participant.id,
            participant_name: participant.combatant_name
          }
        )
      end

      def calculate_xp_reward(participant)
        opponent = battle.battle_participants.where.not(team: participant&.team).first
        level = opponent&.npc_template&.level || opponent&.character&.level || 1
        (50 + level * 10).clamp(10, 500)
      end

      def calculate_gold_reward(participant)
        opponent = battle.battle_participants.where.not(team: participant&.team).first
        level = opponent&.npc_template&.level || opponent&.character&.level || 1
        (10 + level * 5).clamp(5, 200)
      end

      def extract_stat(entity, stat_name)
        return 10 unless entity

        if entity.respond_to?(:stats) && entity.stats.respond_to?(:get)
          entity.stats.get(stat_name).to_i
        elsif entity.respond_to?(stat_name)
          entity.public_send(stat_name).to_i
        else
          10
        end
      end
    end

    # Class methods for initiative calculation
    class << self
      def calculate_initiative(character)
        base = 10
        agility = begin
          character.stats&.get(:agility).to_i
        rescue
          10
        end
        base + agility + rand(1..5)
      end

      def calculate_npc_initiative(npc)
        base = 10
        level = npc.level || 1
        base + level + rand(1..5)
      end
    end

    # Result struct for service responses
    Result = Struct.new(:success, :data, :error, keyword_init: true) do
      def self.success(**data)
        new(success: true, data: data, error: nil)
      end

      def self.failure(message)
        new(success: false, data: {}, error: message)
      end

      def success?
        success
      end

      def [](key)
        data[key]
      end
    end
  end
end
