# frozen_string_literal: true

module Economy
  # Centralizes logic for marketplace/auction taxation, factoring clan ownership and sinks.
  #
  # Usage:
  #   Economy::TaxCalculator.new(base_rate: 0.05).call(location: "capital", clan: owning_clan)
  #
  # Returns:
  #   Float tax rate value.
  class TaxCalculator
    def initialize(base_rate: 0.05, region_catalog: Game::World::RegionCatalog.instance)
      @base_rate = base_rate
      @region_catalog = region_catalog
    end

    def call(location:, clan: nil, listing_value: 0)
      modifier = clan&.clan_territories&.find_by(territory_key: location)&.tax_rate || 0
      region = region_catalog.region_for_territory(location)
      region_modifier = region&.tax_bonus_rate.to_f
      volume_penalty = ((listing_value > 100_000) ? 0.02 : 0)
      (base_rate + modifier + volume_penalty + region_modifier).round(4)
    end

    private

    attr_reader :base_rate, :region_catalog
  end
end
