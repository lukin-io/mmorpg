# frozen_string_literal: true

module Characters
  # Atomically applies the existing tiered skill progression while keeping the
  # Neverlands combat and peace point pools independent.
  class SkillAllocationService
    class AllocationError < StandardError; end

    Result = Data.define(:skills, :combat_points_remaining, :peace_points_remaining)

    def initialize(character:)
      @character = character
    end

    def call(allocations:)
      requested = normalize(allocations)
      raise AllocationError, "No skills selected" if requested.empty?

      character.with_lock do
        character.reload
        updates, spent = build_updates(requested)
        raise AllocationError, "No allocatable skills selected" if updates.empty?
        raise AllocationError, "Not enough combat points" if spent[:combat] > character.available_combat_skill_points
        raise AllocationError, "Not enough peace points" if spent[:peace] > character.available_peace_skill_points

        character.update!(
          passive_skills: character.passive_skills.to_h.merge(updates),
          combat_skill_points: character.available_combat_skill_points - spent[:combat],
          peace_skill_points: character.available_peace_skill_points - spent[:peace]
        )
        character.clear_passive_skill_cache!

        Result.new(
          skills: updates,
          combat_points_remaining: character.available_combat_skill_points,
          peace_points_remaining: character.available_peace_skill_points
        )
      end
    end

    private

    attr_reader :character

    def normalize(allocations)
      allocations.to_h.each_with_object({}) do |(key, raw_spends), result|
        spends = Integer(raw_spends, exception: false)
        next unless spends&.positive?

        result[key.to_s] = spends
      end
    end

    def build_updates(requested)
      formula = Game::Formulas::SkillProgressionFormula.new
      spent = {combat: 0, peace: 0}
      updates = {}

      requested.each do |skill_key, requested_spends|
        definition = Game::Skills::PassiveSkillRegistry.find(skill_key)
        next unless definition

        pool = definition.fetch(:pool, :combat).to_sym
        max_level = definition.fetch(:max_level, 100)
        current_level = character.base_passive_skill_level(skill_key)
        actual_spends = 0

        requested_spends.times do
          break if current_level >= max_level

          current_level = formula.apply_spend(
            current_level:,
            progression_rate: definition[:progression_rate]
          )
          current_level = [current_level, max_level].min
          actual_spends += 1
        end

        next if actual_spends.zero?

        updates[skill_key] = current_level
        spent[pool] += actual_spends
      end

      [updates, spent]
    end
  end
end
