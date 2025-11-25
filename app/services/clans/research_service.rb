# frozen_string_literal: true

module Clans
  # ResearchService manages clan-wide research tracks (resource yield,
  # crafting speed, etc.). Designers author tracks/tiers in
  # config/gameplay/clans.yml; this service queues projects and records
  # contributions until requirements are met.
  #
  # Usage:
  #   service = Clans::ResearchService.new(clan: clan, membership: membership)
  #   project = service.queue!(track: "resource_yield", tier: 1)
  #   service.contribute!(project:, resource_key: "refined_lumber", amount: 10)
  class ResearchService
    def initialize(clan:, membership:, logger: Clans::LogWriter.new(clan:), config: Rails.configuration.x.clans)
      @clan = clan
      @membership = membership
      @logger = logger
      @config = config
    end

    def queue!(track:, tier:)
      template = track_template(track, tier)
      key = "#{track}:#{tier}"

      clan.clan_research_projects.find_or_create_by!(project_key: key) do |project|
        project.requirements = template.fetch("cost", {})
        project.unlocks_payload = template.fetch("unlocks", {})
      end
    end

    def contribute!(project:, resource_key:, amount:)
      project.in_progress! unless project.in_progress? || project.completed?
      project.apply_contribution!(resource_key:, amount:)

      if requirements_met?(project)
        project.update!(status: :completed, completed_at: Time.current)
        apply_unlocks!(project)
      end

      logger.record!(
        action: "research.contribution",
        actor: membership&.user,
        metadata: {project_key: project.project_key, resource_key:, amount: amount}
      )
    end

    private

    attr_reader :clan, :membership, :logger, :config

    def track_template(track, tier)
      config.dig("research", "tracks", track.to_s, "tiers", tier.to_s) ||
        (raise ArgumentError, "Unknown research track #{track}:#{tier}")
    end

    def requirements_met?(project)
      required_items = Array(project.requirements.dig("crafting"))
      required_items.all? do |entry|
        delivered = project.progress.fetch("crafting", {}).fetch(entry["item_key"], 0)
        delivered >= entry["quantity"].to_i
      end
    end

    def apply_unlocks!(project)
      buffs = Array(project.unlocks_payload["buffs"])
      clan.update!(
        unlocked_buffs: (clan.unlocked_buffs + buffs).uniq
      )
      Clans::XpProgression.new(clan: clan).grant!(
        amount: 400,
        source: "research",
        metadata: {project_key: project.project_key}
      )
      logger.record!(
        action: "research.completed",
        metadata: {project_key: project.project_key, unlocks: project.unlocks_payload}
      )
    end
  end
end
