# frozen_string_literal: true

module Companions
  # Calculates pet/mount ability effects that other systems can consume.
  #
  # Usage:
  #   Companions::AbilityService.new(companion: pet).buffs
  class AbilityService
    def initialize(companion:)
      @companion = companion
    end

    def buffs
      species_payload.merge("level_bonus" => companion.level * 0.01)
    end

    private

    attr_reader :companion

    def species_payload
      companion.pet_species.ability_payload
    end
  end
end
