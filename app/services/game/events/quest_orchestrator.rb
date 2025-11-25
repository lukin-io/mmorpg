# frozen_string_literal: true

module Game
  module Events
    # QuestOrchestrator links scheduled event instances with seasonal quests,
    # announcers, leaderboards, and broadcasts so events feel alive.
    class QuestOrchestrator
      def initialize(event_instance,
        dynamic_generator: Game::Quests::DynamicQuestGenerator.new,
        announcement_service: ::Events::AnnouncementService.new(event_instance.game_event))
        @event_instance = event_instance
        @dynamic_generator = dynamic_generator
        @announcement_service = announcement_service
      end

      def prepare!(characters: Character.all)
        assign_event_quests!(characters)
        annotate_world_state!
        broadcast_objectives!
      end

      private

      attr_reader :event_instance, :dynamic_generator, :announcement_service

      def assign_event_quests!(characters)
        triggers = {
          event_key: event_instance.game_event.slug,
          clan_controlled: event_instance.metadata["featured_clan"],
          resource_shortage: event_instance.metadata["resource_focus"]
        }.compact

        characters.find_each do |character|
          dynamic_generator.generate!(character:, triggers:)
        end
      end

      def annotate_world_state!
        reskin_payload = {
          "world_reskin" => event_instance.metadata["world_reskin"],
          "temporary_npc_keys" => event_instance.temporary_npc_keys
        }.compact
        return if reskin_payload.blank?

        event_instance.update!(metadata: event_instance.metadata.merge(reskin_payload))
      end

      def broadcast_objectives!
        objectives = event_instance.community_objectives
        return if objectives.blank?

        summary = objectives.map do |objective|
          "#{objective.title} (#{objective.goal_amount} #{objective.resource_key})"
        end.join(", ")
        announcement_service.broadcast!("Community objectives active: #{summary}")
      end
    end
  end
end
