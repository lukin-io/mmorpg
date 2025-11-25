# frozen_string_literal: true

module Clans
  # QuestBoard starts clan quests from the authored templates and tracks
  # contributions toward completion. When requirements are met the clan earns
  # XP via Clans::XpProgression.
  #
  # Usage:
  #   board = Clans::QuestBoard.new(clan: clan)
  #   board.start!(template_key: "defend_caravans")
  #   board.record_contribution!(quest: quest, character: character, metric: "escort_runs", amount: 1)
  class QuestBoard
    def initialize(clan:, logger: Clans::LogWriter.new(clan:), xp_service: nil, config: Rails.configuration.x.clans)
      @clan = clan
      @logger = logger
      @config = config
      @xp_service = xp_service || Clans::XpProgression.new(clan: clan, logger: logger.class)
    end

    def start!(template_key:)
      template = quest_templates.fetch(template_key.to_s) { raise ArgumentError, "Unknown clan quest #{template_key}" }
      quest_record = Quest.find_by(key: template["quest_key"])

      clan.clan_quests.find_or_create_by!(quest_key: template_key) do |quest|
        quest.quest = quest_record
        quest.requirements = template.fetch("requirements", {})
        quest.progress = {}
        quest.status = :active
        quest.expires_at = 7.days.from_now
      end.tap do |quest|
        logger.record!(action: "quests.started", metadata: {quest_id: quest.id, template_key: template_key})
      end
    end

    def record_contribution!(quest:, character:, metric:, amount:)
      quest.clan_quest_contributions.create!(
        character: character,
        contribution_type: metric,
        amount: amount,
        metadata: {source_character_id: character.id}
      )

      quest.record_progress!(metric, amount)
      quest.complete_if_ready!

      if quest.completed?
        reward_xp = quest_templates.dig(quest.quest_key.to_s, "reward_xp").to_i
        xp_service.grant!(amount: reward_xp, source: "clan_quest", metadata: {quest_id: quest.id})
        logger.record!(action: "quests.completed", metadata: {quest_id: quest.id, reward_xp: reward_xp})
      end
    end

    private

    attr_reader :clan, :logger, :config, :xp_service

    def quest_templates
      config.dig("quests", "templates") || {}
    end
  end
end
