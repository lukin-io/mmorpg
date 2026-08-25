# frozen_string_literal: true

module Game
  # Normalizes the shared probability contract for one developer-authored NPC
  # loot entry. Item/currency persistence remains with the owning domain
  # services; this value object only validates the common entry shape and turns
  # an explicit fractional/percentage chance into a percentage.
  class LootEntry
    class InvalidError < StandardError; end

    attr_reader :attributes, :chance_percent

    # @param raw_entry [Hash] one NPC loot-table entry
    # @return [LootEntry] normalized immutable entry
    # @raise [InvalidError] when the entry or its explicit chance is invalid
    def initialize(raw_entry)
      unless raw_entry.respond_to?(:each_pair)
        raise InvalidError, "Loot entry must be an object"
      end

      @attributes = raw_entry.to_h.with_indifferent_access.freeze
      @chance_percent = normalize_chance
    end

    private

    def normalize_chance
      raise InvalidError, "Loot chance is required" unless attributes.key?(:chance)

      chance = Float(attributes[:chance], exception: false)
      raise InvalidError, "Loot chance must be between 0 and 100" unless chance

      percentage = chance <= 1 ? chance * 100 : chance
      unless percentage.between?(0, 100)
        raise InvalidError, "Loot chance must be between 0 and 100"
      end

      percentage
    end
  end
end
