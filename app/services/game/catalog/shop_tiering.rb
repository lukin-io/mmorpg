# frozen_string_literal: true

module Game
  module Catalog
    # Maps Ashen Veil rarity → soft-release shop tier (1..23) and NV prices.
    class ShopTiering
      RARITY_TIER = {
        "common" => 1,
        "rare" => 5,
        "epic" => 10,
        "mythic" => 15,
        "ancient" => 20,
        "donor" => 23
      }.freeze

      RARITY_PRICE = {
        "common" => 25,
        "rare" => 80,
        "epic" => 220,
        "mythic" => 600,
        "ancient" => 1500,
        "donor" => 5000
      }.freeze

      def self.tier_for(rarity)
        RARITY_TIER.fetch(rarity.to_s, 1)
      end

      def self.price_for(rarity)
        RARITY_PRICE.fetch(rarity.to_s, 25)
      end

      def self.shop_entry(rarity:, position:)
        {
          "sold" => true,
          "mode" => "buy",
          "position" => position,
          "min_level" => tier_for(rarity),
          "tier" => tier_for(rarity)
        }
      end
    end
  end
end
