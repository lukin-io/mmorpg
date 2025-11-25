# frozen_string_literal: true

require "yaml"

module Game
  module Quests
    # StaticQuestBuilder ingests authored quest definitions from
    # config/gameplay/quests/static.yml and upserts Quest records so designers
    # can iterate outside of the database.
    #
    # Usage:
    #   Game::Quests::StaticQuestBuilder.new.sync!
    #
    # Returns:
    #   Array of Quest records that were created/updated.
    class StaticQuestBuilder
      CONFIG_PATH = Rails.root.join("config/gameplay/quests/static.yml")

      def initialize(config_path: CONFIG_PATH)
        @config_path = config_path
      end

      def sync!
        data = YAML.safe_load(config_path.read) || {}
        quests = Array(data["quests"])

        quests.map do |definition|
          upsert_quest(definition)
        end
      end

      private

      attr_reader :config_path

      def upsert_quest(definition)
        quest = Quest.find_or_initialize_by(key: definition.fetch("key"))
        quest.assign_attributes(
          title: definition.fetch("title"),
          summary: definition["summary"],
          quest_type: definition.fetch("quest_type", "main_story"),
          sequence: definition.fetch("sequence", 1),
          chapter: definition.fetch("chapter", 1),
          quest_chain: find_chain(definition["quest_chain_key"]),
          quest_chapter: find_chapter(definition["quest_chapter_key"]),
          difficulty_tier: definition.fetch("difficulty_tier", "story"),
          recommended_party_size: definition.fetch("recommended_party_size", 1),
          min_level: definition.fetch("min_level", 1),
          min_reputation: definition.fetch("min_reputation", 0),
          rewards: definition.fetch("rewards", {}),
          requirements: definition.fetch("requirements", {}),
          metadata: definition.fetch("metadata", {}),
          map_overlays: definition.fetch("map_overlays", {})
        )
        quest.save!
        quest
      end

      def find_chain(key)
        return unless key

        QuestChain.find_or_create_by!(key:, title: key.humanize)
      end

      def find_chapter(key)
        return unless key

        QuestChapter.find_by(key:)
      end
    end
  end
end
