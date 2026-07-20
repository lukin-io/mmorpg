# frozen_string_literal: true

module Game
  module Skills
    class PerkAllocation
      class AllocationError < StandardError; end

      Result = Data.define(:selected_keys, :remaining_points)

      def initialize(character)
        @character = character
      end

      def call(selected_keys:)
        keys = normalize_keys(selected_keys)
        raise AllocationError, "No new perks selected" if keys.empty?

        definitions = keys.index_with { |key| PerkRegistry.find(key) }
        unknown_keys = definitions.select { |_key, definition| definition.nil? }.keys
        raise AllocationError, "Unknown perk selection" if unknown_keys.any?

        character.with_lock do
          new_keys = keys.reject { |key| character.owns_perk?(key) }
          raise AllocationError, "No new perks selected" if new_keys.empty?
          raise AllocationError, "Not enough new-perk points" if new_keys.size > character.perk_points

          selected_and_owned = character.owned_perk_keys + new_keys
          if PerkRegistry.conflicts_for(selected_and_owned).any?
            raise AllocationError, "Selected perks are mutually exclusive"
          end

          character.update!(
            perks: character.perks.merge(new_keys.index_with { true }),
            perk_points: character.perk_points - new_keys.size
          )

          Result.new(selected_keys: new_keys, remaining_points: character.perk_points)
        end
      end

      private

      attr_reader :character

      def normalize_keys(selected_keys)
        Array(selected_keys).filter_map do |key|
          normalized = key.to_s.strip
          normalized if normalized.present?
        end.uniq
      end
    end
  end
end
