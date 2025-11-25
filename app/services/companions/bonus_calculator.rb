# frozen_string_literal: true

module Companions
  # BonusCalculator derives passive buffs granted by a bonded pet companion.
  #
  # Usage:
  #   Companions::BonusCalculator.new(pet: pet).call
  #
  # Returns:
  #   Hash with :combat and :gathering multipliers used by stat services.
  class BonusCalculator
    STAGE_MULTIPLIER = {
      "neutral" => 1.0,
      "friendly" => 1.1,
      "bonded" => 1.25,
      "legendary" => 1.5
    }.freeze

    def initialize(pet:)
      @pet = pet
    end

    def call
      base_payload = pet.pet_species.ability_payload.with_indifferent_access
      multiplier = STAGE_MULTIPLIER.fetch(pet.affinity_stage, 1.0)

      {
        combat: scaled_bonus(base_payload[:combat_bonus], multiplier),
        gathering: scaled_bonus(base_payload[:gathering_bonus], multiplier) + pet.gathering_bonus,
        utility_tags: base_payload[:utility_tags] || []
      }
    end

    private

    attr_reader :pet

    def scaled_bonus(value, multiplier)
      (value.to_f * multiplier).round(2)
    end
  end
end
