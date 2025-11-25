# frozen_string_literal: true

module Clans
  # TerritoryManager swaps ownership of a world territory after war resolution
  # and applies the resulting benefits (tax income, fast travel nodes, etc.).
  #
  # Usage:
  #   Clans::TerritoryManager.new(territory_key: "castle_black").assign!(clan: winning_clan)
  class TerritoryManager
    def initialize(territory_key:, logger: nil)
      @territory_key = territory_key
      @logger = logger
    end

    def assign!(clan:)
      territory = ClanTerritory.find_or_initialize_by(territory_key: territory_key)
      territory.update!(
        clan: clan,
        last_claimed_at: Time.current,
        tax_rate_basis_points: territory.tax_rate_basis_points.presence || 500
      )

      apply_rewards!(clan, territory)

      log_writer(clan).record!(
        action: "territory.claimed",
        metadata: {territory_key: territory_key}
      )
    end

    private

    attr_reader :territory_key, :logger

    def apply_rewards!(clan, territory)
      fast_travel_nodes = (clan.fast_travel_nodes + Array(territory.fast_travel_node)).compact.uniq
      clan.update!(
        fast_travel_nodes: fast_travel_nodes,
        infrastructure_state: clan.infrastructure_state.merge(
          "territories_owned" => clan.clan_territories.count
        )
      )
    end

    def log_writer(clan)
      logger || Clans::LogWriter.new(clan: clan)
    end
  end
end
