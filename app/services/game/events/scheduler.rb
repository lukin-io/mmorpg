# frozen_string_literal: true

module Game
  module Events
    # Scheduler spawns concrete seasonal/tournament instances and orchestrates announcers.
    #
    # Usage:
    #   Game::Events::Scheduler.new(game_event).spawn_instance!(tournament: {...})
    class Scheduler
      def initialize(game_event, announcer_directory: Game::World::PopulationDirectory.instance)
        @game_event = game_event
        @announcer_directory = announcer_directory
      end

      def spawn_instance!(starts_at: game_event.starts_at, ends_at: game_event.ends_at, announcer_npc_key: nil, temporary_npc_keys: [], tournament: nil, community_objectives: [])
        instance = game_event.event_instances.create!(
          starts_at:,
          ends_at:,
          announcer_npc_key: announcer_npc_key || default_announcer,
          temporary_npc_keys: temporary_npc_keys,
          metadata: {scheduled_at: Time.current}
        )

        create_tournament(instance, tournament) if tournament
        create_objectives(instance, community_objectives)
        instance
      end

      private

      attr_reader :game_event, :announcer_directory

      def default_announcer
        event_key = game_event.slug
        announcer_directory.announcer_for_event(event_key)&.key
      end

      def create_tournament(instance, tournament)
        bracket = game_event.competition_brackets.find(tournament.fetch(:competition_bracket_id))
        instance.arena_tournaments.create!(
          competition_bracket: bracket,
          name: tournament.fetch(:name),
          announcer_npc_key: tournament[:announcer_npc_key] || instance.announcer_npc_key,
          metadata: tournament.fetch(:metadata, {})
        )
      end

      def create_objectives(instance, objectives)
        Array(objectives).each do |objective|
          instance.community_objectives.create!(
            title: objective.fetch(:title),
            resource_key: objective.fetch(:resource_key),
            goal_amount: objective.fetch(:goal_amount, 0),
            metadata: objective.fetch(:metadata, {})
          )
        end
      end
    end
  end
end
