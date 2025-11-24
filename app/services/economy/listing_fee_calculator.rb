# frozen_string_literal: true

module Economy
  # ListingFeeCalculator computes upfront listing sinks for auction postings.
  class ListingFeeCalculator
    BASE_RATE = 0.02
    HIGH_VALUE_THRESHOLD = 50_000
    HIGH_VALUE_RATE = 0.03
    MAX_FEE = 10_000
    MIN_FEE = 5

    def initialize(listing_value:, location_modifier: 0.0, clan_modifier: 0.0)
      @listing_value = listing_value.to_i
      @location_modifier = location_modifier
      @clan_modifier = clan_modifier
    end

    def call
      rate = BASE_RATE + location_modifier + clan_modifier
      rate += 0.01 if listing_value >= HIGH_VALUE_THRESHOLD
      fee = (listing_value * rate).round
      fee = MIN_FEE if fee < MIN_FEE
      [fee, MAX_FEE].min
    end

    private

    attr_reader :listing_value, :location_modifier, :clan_modifier
  end
end
