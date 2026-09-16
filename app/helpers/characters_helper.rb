# frozen_string_literal: true

module CharactersHelper
  # A profession is not an allocatable /100 skill. Missing or malformed stored
  # counters display zero; equipment is shown separately and cannot be spent.
  def profession_base_value(character, key)
    counters = character.metadata.to_h["profession_skills"]
    value = counters[key.to_s] if counters.is_a?(Hash)
    value.is_a?(Integer) && value >= 0 ? value : 0
  end
end
