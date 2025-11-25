# frozen_string_literal: true

module Clans
  # StrongholdService manages upgrade jobs (war rooms, command halls, etc.).
  # Designers define templates/requirements in config/gameplay/clans.yml and
  # this service handles queuing plus contribution tracking.
  #
  # Usage:
  #   service = Clans::StrongholdService.new(clan: clan, membership: membership)
  #   upgrade = service.queue!(upgrade_key: "war_room")
  #   service.contribute!(upgrade:, item_key: "steel_ingot", amount: 5)
  class StrongholdService
    def initialize(clan:, membership:, logger: Clans::LogWriter.new(clan:), config: Rails.configuration.x.clans)
      @clan = clan
      @membership = membership
      @logger = logger
      @config = config
    end

    def queue!(upgrade_key:)
      template = upgrade_templates.fetch(upgrade_key.to_s) { raise ArgumentError, "Unknown upgrade #{upgrade_key}" }
      clan.clan_stronghold_upgrades.find_or_create_by!(upgrade_key:) do |upgrade|
        upgrade.requirements = template.fetch("requirements", {})
        upgrade.status = :pending
      end
    end

    def contribute!(upgrade:, item_key:, amount:)
      upgrade.update!(status: :in_progress, started_at: Time.current) if upgrade.pending?
      upgrade.apply_contribution!(item_key:, amount:)

      if requirements_met?(upgrade)
        upgrade.update!(status: :completed, completed_at: Time.current)
        apply_unlocks!(upgrade)
      end

      logger.record!(
        action: "stronghold.contribution",
        actor: membership&.user,
        metadata: {upgrade_key: upgrade.upgrade_key, item_key:, amount: amount}
      )
    end

    private

    attr_reader :clan, :membership, :logger, :config

    def upgrade_templates
      config.dig("stronghold", "upgrade_templates") || {}
    end

    def requirements_met?(upgrade)
      required_items = Array(upgrade.requirements.dig("crafted_items"))
      required_items.all? do |entry|
        delivered = upgrade.progress.fetch("crafted_items", {}).fetch(entry["item_key"], 0)
        delivered >= entry["quantity"].to_i
      end
    end

    def apply_unlocks!(upgrade)
      template = upgrade_templates.fetch(upgrade.upgrade_key)
      unlocks = template.fetch("unlocks", {})
      clan.update!(
        infrastructure_state: clan.infrastructure_state.merge(unlocks)
      )
      logger.record!(
        action: "stronghold.completed",
        metadata: {upgrade_key: upgrade.upgrade_key, unlocks: unlocks}
      )
    end
  end
end
