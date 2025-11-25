# frozen_string_literal: true

module Game
  module Quests
    # MapOverlayPresenter composes quest objective, NPC, and resource node data
    # into a normalized payload for the quest map Turbo frame.
    #
    # Usage:
    #   presenter = Game::Quests::MapOverlayPresenter.new(quest:, character:)
    #   presenter.pins #=> [{type: "npc", label: "..."}]
    class MapOverlayPresenter
      def initialize(quest:, character:, region_catalog: Game::World::RegionCatalog.instance)
        @quest = quest
        @character = character
        @region_catalog = region_catalog
      end

      def pins
        @pins ||= (explicit_nodes + npc_nodes + resource_nodes).uniq
      end

      private

      attr_reader :quest, :character, :region_catalog

      def explicit_nodes
        Array(quest.map_overlays.fetch("nodes", [])).map do |node|
          {
            "type" => node["type"] || "objective",
            "label" => node["label"],
            "zone" => node["zone"] || node["region"],
            "coordinates" => node["coordinates"],
            "npc_key" => node["npc_key"],
            "resource_key" => node["resource_key"]
          }
        end
      end

      def npc_nodes
        quest.quest_steps.where.not(npc_key: nil).map do |step|
          npc = Game::World::PopulationDirectory.instance.npc(step.npc_key)
          {
            "type" => "npc",
            "label" => npc&.name || step.npc_key.humanize,
            "npc_key" => step.npc_key,
            "zone" => npc&.zone_key
          }
        end
      end

      def resource_nodes
        keys = quest.quest_objectives.flat_map do |objective|
          objective.metadata["resource_key"]
        end.compact

        keys.map do |key|
          region = region_for_resource(key)
          {
            "type" => "resource",
            "label" => key.humanize,
            "zone" => region&.name,
            "resource_key" => key
          }
        end
      end

      def region_for_resource(resource_key)
        region_catalog.all.find do |region|
          region_catalog.resource_nodes_for(region.key).include?(resource_key)
        end
      end
    end
  end
end
