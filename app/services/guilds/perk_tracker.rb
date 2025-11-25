# frozen_string_literal: true

module Guilds
  # PerkTracker unlocks level-based guild perks and notifies the community channel.
  # Usage:
  #   Guilds::PerkTracker.new(guild: guild).sync!
  # Returns:
  #   Array of GuildPerk instances that were newly created.
  class PerkTracker
    PERKS = [
      {level: 5, key: "bank_tab_2", metadata: {"description" => "Unlocks a second guild bank tab."}},
      {level: 10, key: "travel_banner", metadata: {"description" => "Banner teleport from social hubs."}},
      {level: 15, key: "guild_contracts", metadata: {"description" => "Enables profession commissions via guild listings."}}
    ].freeze

    def initialize(guild:, announcer: ->(perk) { announce(perk) })
      @guild = guild
      @announcer = announcer
    end

    def sync!
      unlocked_keys = guild.guild_perks.pluck(:perk_key)
      created = []

      PERKS.each do |perk|
        next if perk[:level] > guild.level
        next if unlocked_keys.include?(perk[:key])

        created << guild.guild_perks.create!(
          perk_key: perk[:key],
          source_level: perk[:level],
          unlocked_at: Time.current,
          metadata: perk[:metadata]
        ).tap { |record| announcer.call(record) }
      end

      created
    end

    private

    attr_reader :guild, :announcer

    def announce(perk)
      Social::CommunityAnnouncementJob.perform_later(
        event: "guild_perk_unlocked",
        payload: {
          guild_id: guild.id,
          guild_name: guild.name,
          perk_key: perk.perk_key
        }
      )
    end
  end
end
