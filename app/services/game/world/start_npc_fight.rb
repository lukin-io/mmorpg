# frozen_string_literal: true

module Game
  module World
    # Starts the shared combat flow for a hostile NPC materialized on the
    # character's current outdoor cell.
    class StartNpcFight
      class FightViolationError < StandardError; end

      def initialize(
        character:,
        tile_npc:,
        return_context: "world",
        rng: Random.new,
        roster_selector_class: EncounterRosterSelector
      )
        @character = character
        @tile_npc = tile_npc
        @return_context = return_context
        @rng = rng
        @roster_selector_class = roster_selector_class
      end

      def call
        raise FightViolationError, "NPC is unavailable." unless tile_npc

        match = nil
        ActiveRecord::Base.transaction do
          character.with_lock do
            character.reload
            match = active_match

            unless match
              tile_npc.with_lock do
                tile_npc.reload
                validate!
                match = create_match!
                create_participations!(match)
                Arena::CombatProcessor.new(match).start_match
              end
            end
            # A synchronous action can start combat before its passive timer fires.
            # Consume that timer too, so Finish schedules a fresh encounter wait.
            character.reload
            schedule_key = PassiveEncounterCheck::SCHEDULE_METADATA_KEY
            if character.metadata.to_h.key?(schedule_key)
              character.update!(metadata: character.metadata.to_h.except(schedule_key))
            end
            WorldActionOffer.timed_local_actions.where(character:).update_all(
              status: WorldActionOffer.statuses.fetch("cancelled"),
              updated_at: Time.current
            )
          end
        end

        match
      end

      private

      attr_reader :character, :tile_npc, :return_context, :rng, :roster_selector_class

      def validate!
        if character.active_airship_journey
          raise FightViolationError, "Disembark before interacting with ground NPCs."
        end

        if MovementCommand.moving.where(character:).exists?
          raise FightViolationError, "Movement already in progress."
        end
        raise FightViolationError, "NPC is unavailable." unless tile_npc&.alive?
        raise FightViolationError, "This NPC is not hostile." unless tile_npc.hostile?
        raise FightViolationError, "NPC is not on the current cell." unless npc_matches_position?
        encounter_selection
      rescue EncounterRosterSelector::InvalidRosterError => error
        raise FightViolationError, error.message
      end

      def npc_matches_position?
        position = character.position
        position.present? &&
          position.zone.name == tile_npc.zone &&
          position.x == tile_npc.x &&
          position.y == tile_npc.y
      end

      def active_match
        character.arena_participations
          .joins(:arena_match)
          .merge(ArenaMatch.active)
          .order("arena_participations.created_at DESC")
          .first
          &.arena_match
      end

      def encounter_selection
        @encounter_selection ||= roster_selector_class.new(tile_npc:, rng:).call
      end

      def normalized_return_context
        @normalized_return_context ||= CombatReturnContext.new(character:).normalize(return_context)
      end

      def create_match!
        members = encounter_selection.members
        metadata = {
          "source" => "world_npc",
          "fight_kind" => "free",
          "is_npc_fight" => true,
          "tile_npc_id" => tile_npc.id,
          "npc_template_id" => tile_npc.npc_template_id,
          "npc_name" => tile_npc.npc_template.name,
          "npc_role" => tile_npc.npc_template.role,
          "encounter_count" => members.size,
          "encounter_member_keys" => members.map { |member| member.npc_template.npc_key },
          "repeatable_encounter_source" => tile_npc.repeatable_encounter_source?,
          "return_context" => normalized_return_context,
          "zone" => tile_npc.zone,
          "x" => tile_npc.x,
          "y" => tile_npc.y,
          "fight_timeout_seconds" => ArenaMatch::DEFAULT_TURN_TIMEOUT
        }
        if encounter_selection.sample_key.present?
          metadata["encounter_roster_sample"] = encounter_selection.sample_key
        end
        unless encounter_selection.experience_reward.nil?
          metadata["encounter_experience_reward"] = encounter_selection.experience_reward
        end
        unless encounter_selection.defeat_experience_reward.nil?
          metadata["encounter_defeat_experience_reward"] = encounter_selection.defeat_experience_reward
        end
        source_metadata = tile_npc.metadata.to_h
        metadata["combat_profile"] = source_metadata[:combat_profile] if source_metadata[:combat_profile].present?
        metadata["combat_profile"] ||= source_metadata["combat_profile"] if source_metadata["combat_profile"].present?

        ArenaMatch.create!(
          zone: character.position.zone,
          match_type: members.size > 1 ? :team_battle : :duel,
          status: :pending,
          turn_timeout_seconds: ArenaMatch::DEFAULT_TURN_TIMEOUT,
          trauma_percent: encounter_selection.trauma_percent,
          metadata:
        )
      end

      def create_participations!(match)
        ArenaParticipation.create!(
          arena_match: match,
          character:,
          user: character.user,
          team: "a",
          joined_at: Time.current
        )

        encounter_selection.members.each_with_index do |member, index|
          ArenaParticipation.create!(
            arena_match: match,
            npc_template: member.npc_template,
            team: "b",
            joined_at: Time.current,
            metadata: member.metadata.merge(
              "current_hp" => member.max_hp,
              "max_hp" => member.max_hp,
              "level" => member.level,
              "tile_npc_id" => tile_npc.id,
              "encounter_slot" => index + 1,
              "encounter_roster_sample" => encounter_selection.sample_key
            )
          )
        end
      end
    end
  end
end
