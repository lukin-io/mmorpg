# frozen_string_literal: true

module Game
  module World
    # NpcArchetype wraps deterministic NPC metadata and reputation gates.
    #
    # Usage:
    #   archetype = Game::World::NpcArchetype.new("magistrate_serra", config)
    #   archetype.reaction_for(reputation: 15) # => :friendly
    #
    # Returns:
    #   PORO exposing helper predicates for dialogue and feature gating.
    class NpcArchetype
      attr_reader :key, :name, :archetype, :region, :location, :roles,
        :dialogue, :reputation_thresholds, :quests, :faction_alignment,
        :moderation_categories, :training_offers, :inventory_tags, :event_hooks

      def initialize(key, config)
        @key = key.to_s
        @name = config.fetch("name")
        @archetype = config.fetch("archetype")
        @region = config.fetch("region")
        @location = config.fetch("location")
        @roles = config.fetch("roles", [])
        @dialogue = config.fetch("dialogue", {})
        @reputation_thresholds = config.fetch("reputation_thresholds", {})
        @quests = config.fetch("quests", {})
        @faction_alignment = config["faction_alignment"]
        @moderation_categories = config.fetch("moderation_categories", [])
        @training_offers = config.fetch("training_offers", {})
        @inventory_tags = config.fetch("inventory_tags", [])
        @event_hooks = config.fetch("event_hooks", {})
      end

      def reaction_for(reputation:)
        friendly_floor = reputation_thresholds.fetch("friendly", 0)
        guarded_floor = reputation_thresholds.fetch("guarded", friendly_floor / 2)
        hostile_ceiling = reputation_thresholds.fetch("hostile", -Float::INFINITY)

        return :hostile if reputation <= hostile_ceiling
        return :friendly if reputation >= friendly_floor
        return :guarded if reputation >= guarded_floor

        :neutral
      end

      def hostile?(reputation:)
        reaction_for(reputation:) == :hostile
      end

      def offers_reports?
        roles.include?("report_intake") && moderation_categories.any?
      end
    end
  end
end
