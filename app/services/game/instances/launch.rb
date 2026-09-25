# frozen_string_literal: true

module Game
  module Instances
    # Launches a catalog dungeon/raid encounter as an arena NPC match.
    class Launch
      Result = Struct.new(:success?, :match, :message, keyword_init: true)

      def initialize(character:, instance_kind:, instance_id:)
        @character = character
        @instance_kind = instance_kind.to_s
        @instance_id = instance_id.to_s
      end

      def call
        catalog = load_instance
        return fail!(I18n.t("game.instances.missing")) unless catalog

        enemy_id = first_enemy_id(catalog)
        return fail!(I18n.t("game.instances.no_enemy")) if enemy_id.blank?

        template = NpcTemplate.find_by(npc_key: "av_#{enemy_id}")
        return fail!(I18n.t("game.instances.npc_missing", id: enemy_id)) unless template

        room = ArenaRoom.active.order(:level_min).first
        return fail!(I18n.t("game.instances.no_room")) unless room

        if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
          return fail!(I18n.t("game.fight.already_in_fight"))
        end

        match = nil
        ActiveRecord::Base.transaction do
          character.with_lock do
            character.reload
            match = ArenaMatch.create!(
              arena_room: room,
              match_type: :duel,
              status: :pending,
              turn_timeout_seconds: 60,
              trauma_percent: 10,
              metadata: {
                "instance_kind" => instance_kind,
                "instance_id" => instance_id,
                "instance_name" => catalog.dig("name", "ru-RU") || instance_id,
                "is_npc_fight" => true,
                "npc_template_id" => template.id,
                "return_context" => "instances"
              }
            )
            ArenaParticipation.create!(
              arena_match: match,
              character: character,
              user: character.user,
              team: "a",
              joined_at: Time.current
            )
            npc_hp = template.respond_to?(:health) ? template.health : template.metadata.to_h["health"].to_i
            npc_hp = npc_hp.to_i.clamp(1, 50_000)
            ArenaParticipation.create!(
              arena_match: match,
              npc_template: template,
              team: "b",
              joined_at: Time.current,
              metadata: {"current_hp" => npc_hp, "max_hp" => npc_hp}
            )
            Arena::CombatProcessor.new(match).start_match
            Game::Activity::Tracker.new(character:).record!(kind: "instance_launch", amount: 1, meta: {
              "instance_kind" => instance_kind,
              "instance_id" => instance_id
            })
          end
        end

        Result.new(success?: true, match: match, message: I18n.t("game.instances.started"))
      rescue StandardError => error
        Result.new(success?: false, message: error.message)
      end

      private

      attr_reader :character, :instance_kind, :instance_id

      def load_instance
        payload = if instance_kind == "raid"
          Game::Catalog::AshenVeilFiles.raids
        else
          Game::Catalog::AshenVeilFiles.dungeons
        end
        list = payload[instance_kind == "raid" ? "raids" : "dungeons"] || []
        list.find { |row| row["id"].to_s == instance_id }
      end

      def first_enemy_id(catalog)
        if instance_kind == "raid"
          catalog.dig("encounters", 0, "enemyId")
        else
          catalog.dig("rooms", 0, "enemyId")
        end
      end

      def fail!(message)
        Result.new(success?: false, message: message)
      end
    end
  end
end
