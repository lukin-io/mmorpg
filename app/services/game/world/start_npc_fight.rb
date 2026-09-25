# frozen_string_literal: true

module Game
  module World
    # Starts the shared combat flow for a hostile NPC materialized on the
    # character's current outdoor cell.
    #
    # Ashen personal instances: the tile stays available for every player
    # (no shared respawn lock). Pack size follows AggroPackSize; bot stats and
    # scarce set-piece loot come from NpcLoadout attached to participations.
    class StartNpcFight
      class FightViolationError < StandardError; end

      def initialize(
        character:,
        tile_npc:,
        return_context: "world",
        rng: Random.new,
        roster_selector_class: EncounterRosterSelector,
        allow_off_cell: false
      )
        @character = character
        @tile_npc = tile_npc
        @return_context = return_context
        @rng = rng
        @roster_selector_class = roster_selector_class
        @allow_off_cell = allow_off_cell
      end

      def call
        raise FightViolationError, I18n.t("game.quests.npc_unavailable") unless tile_npc

        match = nil
        ActiveRecord::Base.transaction do
          character.with_lock do
            character.reload
            match = active_match

            unless match
              if tile_npc.personal_instance?
                tile_npc.reload
                validate!
                match = create_match!
                create_participations!(match)
                Arena::CombatProcessor.new(match).start_match
              else
                tile_npc.with_lock do
                  tile_npc.reload
                  validate!
                  match = create_match!
                  create_participations!(match)
                  Arena::CombatProcessor.new(match).start_match
                end
              end
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

      attr_reader :character, :tile_npc, :return_context, :rng, :roster_selector_class, :allow_off_cell

      def validate!
        raise FightViolationError, I18n.t("game.flashes.disembark_first") if character.active_airship_journey

        if MovementCommand.moving.where(character:).exists?
          raise FightViolationError, I18n.t("game.flashes.movement_in_progress")
        end
        raise FightViolationError, I18n.t("game.quests.npc_unavailable") unless tile_npc&.alive?
        raise FightViolationError, I18n.t("game.quests.npc_not_hostile") unless tile_npc.hostile?
        raise FightViolationError, I18n.t("game.quests.npc_wrong_cell") unless allow_off_cell || npc_matches_position?
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
        @encounter_selection ||= roster_selector_class.new(
          tile_npc:,
          character:,
          rng:
        ).call
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
          "personal_instance" => tile_npc.personal_instance?,
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
          # Turn inactivity (5 min) owns timeouts; do not wall-clock end at 5 min from start.
          "fight_timeout_seconds" => ArenaMatch::ABSOLUTE_FIGHT_CEILING
        }
        if encounter_selection.sample_key.present?
          metadata["encounter_roster_sample"] = encounter_selection.sample_key
        end
        unless encounter_selection.experience_reward.nil?
          metadata["encounter_experience_reward"] = encounter_selection.experience_reward
        end
        source_metadata = tile_npc.metadata.to_h
        metadata["combat_profile"] = source_metadata[:combat_profile] if source_metadata[:combat_profile].present?
        metadata["combat_profile"] ||= source_metadata["combat_profile"] if source_metadata["combat_profile"].present?
        metadata["drop_chance_multiplier"] = source_metadata["drop_chance_multiplier"] if source_metadata["drop_chance_multiplier"].present?

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
          loadout = member_loadout(member)
          max_hp = loadout ? loadout.combat_stats["hp"].to_i : member.max_hp
          max_hp = member.max_hp if max_hp <= 0
          participation_metadata = member.metadata.merge(
            "current_hp" => max_hp,
            "max_hp" => max_hp,
            "level" => member.level,
            "tile_npc_id" => tile_npc.id,
            "encounter_slot" => index + 1,
            "encounter_roster_sample" => encounter_selection.sample_key
          )
          if loadout
            participation_metadata["equipped_set_keys"] = loadout.item_keys
            participation_metadata["equipped_set_id"] = loadout.set_id
            participation_metadata["equipped_set_tier"] = loadout.set_tier
            participation_metadata["combat_archetype"] = loadout.archetype
            participation_metadata["combat_stats"] = loadout.combat_stats
          end

          ArenaParticipation.create!(
            arena_match: match,
            npc_template: member.npc_template,
            team: "b",
            joined_at: Time.current,
            metadata: participation_metadata
          )
        end
      end

      def member_loadout(member)
        # Always derive set-floor combat stats for wilderness NPCs so authored
        # soft bots cannot undercut the soft-launch gear necessity curve.
        tier = tile_npc.metadata.to_h["world_tier"] ||
          member.npc_template.metadata.to_h["world_tier"] ||
          [member.level.to_i, 1].max.clamp(1, 23)
        NpcLoadout.new(npc_template: member.npc_template, world_tier: tier, rng:).call
      end
    end
  end
end
