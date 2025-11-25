# frozen_string_literal: true

module Game
  module Quests
    # QuestGateEvaluator centralizes the logic for validating whether a
    # character satisfies the gating requirements for a quest or chapter.
    # It inspects level, reputation, and faction alignment rules so both the
    # controller layer and background jobs can share the same gate semantics.
    #
    # Usage:
    #   Game::Quests::QuestGateEvaluator.new(character:, quest:).call
    #
    # Returns:
    #   Result struct responding to #allowed? and #reasons.
    class QuestGateEvaluator
      Result = Struct.new(:allowed, :reasons, keyword_init: true) do
        def allowed?
          allowed
        end
      end

      def initialize(character:, quest: nil, chapter: nil, extra_requirements: {})
        @character = character
        @quest = quest
        @chapter = chapter || quest&.quest_chapter
        @extra_requirements = extra_requirements
      end

      def call
        failures = []
        combined_requirements.each do |key, value|
          next if value.blank?

          case key.to_sym
          when :min_level
            failures << failure(:level, required: value, actual: character.level) if character.level < value
          when :min_reputation
            failures << failure(:reputation, required: value, actual: character.reputation) if character.reputation < value
          when :faction_alignment
            Array(value).map(&:to_s)
              .then { |alignments| failures << failure(:faction_alignment, required: alignments, actual: character.faction_alignment) unless alignments.include?(character.faction_alignment) }
          end
        end

        Result.new(allowed: failures.empty?, reasons: failures)
      end

      private

      attr_reader :character, :quest, :chapter, :extra_requirements

      def combined_requirements
        chapter_requirements = chapter&.gating_payload || {}
        quest_requirements = quest&.gating_requirements || {}

        chapter_requirements
          .merge(quest_requirements)
          .merge(extra_requirements.symbolize_keys)
      end

      def failure(type, required:, actual:)
        {
          type: type,
          required: required,
          actual: actual
        }
      end
    end
  end
end
