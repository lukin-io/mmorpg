# frozen_string_literal: true

module Players
  module Progression
    # ExperiencePipeline standardizes XP rewards from quests, combat, and gathering while tracking contribution mix.
    #
    # Usage:
    #   Players::Progression::ExperiencePipeline.new(character:).grant!(quest: 120, combat: 80)
    #
    # Returns:
    #   Character after XP + source ledger updates.
    class ExperiencePipeline
      SOURCE_KEYS = %w[quest combat gathering premium].freeze

      def initialize(character:, level_up_service: Players::Progression::LevelUpService.new(character:))
        @character = character
        @level_up_service = level_up_service
      end

      def grant!(xp_by_source = {})
        total_xp = 0

        Character.transaction do
          xp_by_source.each do |source, amount|
            normalized_source = normalize_source(source)
            next unless normalized_source

            amount = amount.to_i
            next if amount <= 0

            increment_source!(normalized_source, amount)
            total_xp += amount
          end

          level_up_service.apply_experience!(total_xp) if total_xp.positive?
        end

        character
      end

      private

      attr_reader :character, :level_up_service

      def increment_source!(source, amount)
        character.progression_sources_will_change!
        current = character.progression_sources.fetch(source, 0)
        character.progression_sources[source] = current + amount
        character.save!
      end

      def normalize_source(source)
        key = source.to_s.downcase
        SOURCE_KEYS.include?(key) ? key : nil
      end
    end
  end
end
