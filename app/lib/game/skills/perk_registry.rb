# frozen_string_literal: true

module Game
  module Skills
    # Source-backed registry for Neverlands boolean `Navyki` perks.
    #
    # Only named, live-captured perks are selectable. The source exclusion
    # table is retained by numeric id so newly captured branches can be added
    # without inventing relationships or labels.
    class PerkRegistry
      PERK_ROWS = [
        [7, :more_strength, "More Strength", "Больше силы", :stat]
      ].freeze

      EXCLUSIONS_BY_SOURCE_ID = {
        24 => [27, 19, 38, 14, 40, 39, 32, 5, 41],
        27 => [24, 19, 38, 14, 40, 39, 32, 5, 41],
        25 => [26, 19, 38, 14, 40, 39, 32, 5, 41],
        26 => [25, 19, 38, 14, 40, 39, 32, 5, 41],
        14 => [24, 25, 26, 27, 19, 38, 39, 32, 5, 41],
        32 => [24, 25, 26, 27, 19, 38, 14, 40, 5, 41],
        38 => [24, 25, 26, 27, 14, 40, 39, 32, 5, 41],
        40 => [24, 25, 26, 27, 19, 38, 39, 32, 5, 41],
        5 => [24, 25, 26, 27, 19, 38, 14, 40, 39, 32],
        19 => [24, 25, 26, 27, 14, 40, 39, 32, 5, 41],
        39 => [24, 25, 26, 27, 19, 38, 14, 40, 5, 41],
        41 => [24, 25, 26, 27, 19, 38, 14, 40, 39, 32]
      }.transform_values(&:freeze).freeze

      PERKS = PERK_ROWS.each_with_object({}) do |(source_id, key, name, source_name, category), memo|
        memo[key] = {
          key:,
          source_id:,
          name:,
          source_name:,
          category:,
          description: "Adds one effective Strength for every two character levels, rounded down."
        }
      end.freeze

      SOURCE_ID_INDEX = PERKS.transform_values { |definition| definition[:source_id] }.invert.freeze

      class << self
        def find(perk_key)
          return nil if perk_key.blank?

          PERKS[perk_key.to_sym]
        end

        def find_by_source_id(source_id)
          key = SOURCE_ID_INDEX[source_id.to_i]
          key ? find(key) : nil
        end

        def all
          PERKS
        end

        def all_keys
          PERKS.keys
        end

        def excluded_source_ids_for(source_id)
          EXCLUSIONS_BY_SOURCE_ID.fetch(source_id.to_i, [])
        end

        def conflicts_for(perk_keys)
          definitions = Array(perk_keys).filter_map { |key| find(key) }
          selected_ids = definitions.map { |definition| definition[:source_id] }

          definitions.each_with_object([]) do |definition, conflicts|
            excluded_source_ids_for(definition[:source_id]).each do |excluded_id|
              next unless selected_ids.include?(excluded_id)

              conflicts << [definition[:source_id], excluded_id].sort
            end
          end.uniq
        end
      end
    end
  end
end
