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
    def initialize(base_rate: 0.05)
      @base_rate = base_rate
    end

    def call(location:, clan: nil, listing_value: 0)
      modifier = clan&.clan_territories&.find_by(territory_key: location)&.tax_rate || 0
      volume_penalty = listing_value > 100_000 ? 0.02 : 0
      (base_rate + modifier + volume_penalty).round(4)
    end

    private

    attr_reader :base_rate
  end
end

