# frozen_string_literal: true

module Analytics
  # QuestTracker emits lightweight ActiveSupport::Notifications events so
  # analytics jobs and dashboards can aggregate quest performance without
  # coupling gameplay services to a specific persistence layer.
  #
  # Usage:
  #   Analytics::QuestTracker.track_completion!(quest: quest, character: char, duration_seconds: 480)
  module QuestTracker
    TOPIC = "quests.analytics"

    module_function

    def track_completion!(quest:, character:, duration_seconds:)
      instrument(
        "completion",
        quest_id: quest.id,
        quest_key: quest.key,
        quest_chain_key: quest.quest_chain&.key,
        character_id: character.id,
        duration_seconds: duration_seconds
      )
    end

    def track_failure!(quest:, character:, reason:)
      instrument(
        "failure",
        quest_id: quest.id,
        quest_key: quest.key,
        quest_chain_key: quest.quest_chain&.key,
        character_id: character.id,
        reason: reason
      )
    end

    def track_abandonment!(quest:, character:, reason:)
      instrument(
        "abandonment",
        quest_id: quest.id,
        quest_key: quest.key,
        quest_chain_key: quest.quest_chain&.key,
        character_id: character.id,
        reason: reason
      )
    end

    def instrument(suffix, payload)
      ActiveSupport::Notifications.instrument("#{TOPIC}.#{suffix}", payload)
    end
    private_class_method :instrument
  end
end
