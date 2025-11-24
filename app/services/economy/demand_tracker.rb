# frozen_string_literal: true

module Economy
  # DemandTracker records crafting outputs as demand signals and routes medical
  # supplies into local infirmary stockpiles.
  class DemandTracker
    MEDICAL_MATCHERS = [/bandage/i, /salve/i, /poultice/i, /kit/i].freeze

    def self.record_crafting!(recipe:, item_name:, quantity:, zone: nil)
      new(recipe:, item_name:, quantity:, zone: zone).record!
    end

    def initialize(recipe:, item_name:, quantity:, zone:)
      @recipe = recipe
      @item_name = item_name
      @quantity = quantity.to_i
      @zone = zone
    end

    def record!
      return unless quantity.positive?

      MarketDemandSignal.create!(
        source: "crafting",
        item_name: item_name,
        quantity: quantity,
        profession: recipe.profession,
        zone: zone,
        recorded_at: Time.current,
        metadata: {
          recipe_id: recipe.id,
          tier: recipe.tier
        }
      )
      restock_medical_supply! if medical_supply?
    end

    private

    attr_reader :recipe, :item_name, :quantity, :zone

    def medical_supply?
      recipe.profession&.name&.match?(/doctor/i) ||
        MEDICAL_MATCHERS.any? { |matcher| matcher.match?(item_name) }
    end

    def restock_medical_supply!
      return unless zone

      pool = MedicalSupplyPool.find_or_create_by!(zone: zone, item_name: item_name)
      pool.restock!(quantity)
    end
  end
end
