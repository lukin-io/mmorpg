# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Calculates damage reduction from elemental and physical resistance skills.
    #
    # Inputs:
    #   - defender: Character or NPC with passive skill levels
    #   - damage: Integer - raw damage amount before resistance
    #   - element: String/Symbol - damage element type (fire, ice, lightning, physical, etc.)
    #   - rng: Random instance for deterministic results (default: Random.new)
    #
    # Returns:
    #   Hash with :final_damage, :original_damage, :reduction, :resistance_level, :element
    #
    # Usage:
    #   formula = Game::Formulas::ResistanceFormula.new(rng: Random.new(123))
    #   result = formula.call(defender: mage, damage: 100, element: :fire)
    #   # => { final_damage: 60, original_damage: 100, reduction: 0.4, resistance_level: 100, element: :fire }
    #
    class ResistanceFormula
      # Maximum damage reduction per element type
      MAX_REDUCTION = {
        fire: 0.40,        # 40% max fire damage reduction
        ice: 0.40,         # 40% max ice/cold damage reduction
        cold: 0.40,        # Alias for ice
        water: 0.40,       # Alias for ice
        lightning: 0.40,   # 40% max lightning damage reduction
        air: 0.40,         # Alias for lightning
        earth: 0.35,       # 35% max earth damage reduction
        arcane: 0.30,      # 30% max arcane damage reduction
        physical: 0.25,    # 25% max physical damage reduction
        nature: 0.35,      # 35% max nature damage reduction
        dark: 0.35,        # 35% max dark damage reduction
        light: 0.35        # 35% max light damage reduction
      }.freeze

      # Mapping from element to resistance skill
      ELEMENT_TO_SKILL = {
        fire: :fire_resistance,
        ice: :cold_resistance,
        cold: :cold_resistance,
        water: :cold_resistance,
        lightning: :lightning_resistance,
        air: :lightning_resistance,
        earth: :physical_fortitude,  # Earth uses physical fortitude
        physical: :physical_fortitude,
        melee: :physical_fortitude,
        ranged: :physical_fortitude,
        nature: :physical_fortitude,
        arcane: :spell_mastery,      # Arcane uses spell mastery
        dark: :physical_fortitude,
        light: :physical_fortitude
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Calculate damage after applying resistance
      #
      # @param defender [Character, NpcTemplate, BattleParticipant] the defender
      # @param damage [Integer] raw damage before resistance
      # @param element [String, Symbol] the damage element type
      # @return [Hash] result with damage values and reduction info
      def call(defender:, damage:, element: :physical)
        element_sym = normalize_element(element)
        resistance_skill = ELEMENT_TO_SKILL[element_sym] || :physical_fortitude
        max_reduction = MAX_REDUCTION[element_sym] || 0.25

        # Get resistance level from defender
        resistance_level = extract_resistance_level(defender, resistance_skill)

        # Calculate reduction percentage (0 to max_reduction)
        # At level 100, get full max_reduction
        reduction = (resistance_level.to_f / 100.0) * max_reduction

        # Apply any equipment bonuses
        equipment_bonus = extract_equipment_resistance(defender, element_sym)
        reduction += equipment_bonus

        # Cap reduction at max_reduction + 10% for equipment
        reduction = reduction.clamp(0.0, max_reduction + 0.10)

        # Apply reduction to damage
        final_damage = (damage * (1.0 - reduction)).round
        final_damage = [final_damage, 1].max # Minimum 1 damage

        {
          final_damage: final_damage,
          original_damage: damage,
          reduction: reduction.round(3),
          reduction_percent: (reduction * 100).round(1),
          resistance_level: resistance_level,
          resistance_skill: resistance_skill,
          element: element_sym,
          equipment_bonus: equipment_bonus
        }
      end

      # Batch apply resistances to multiple damage instances
      #
      # @param defender [Character, NpcTemplate] the defender
      # @param damages [Array<Hash>] array of {damage:, element:} hashes
      # @return [Array<Hash>] array of resistance results
      def apply_multiple(defender:, damages:)
        damages.map do |d|
          call(defender: defender, damage: d[:damage], element: d[:element])
        end
      end

      # Get all resistance levels for a defender
      #
      # @param defender [Character, NpcTemplate] the defender
      # @return [Hash] resistance levels by element
      def all_resistances(defender)
        {
          fire: extract_resistance_level(defender, :fire_resistance),
          cold: extract_resistance_level(defender, :cold_resistance),
          lightning: extract_resistance_level(defender, :lightning_resistance),
          physical: extract_resistance_level(defender, :physical_fortitude),
          arcane: extract_resistance_level(defender, :spell_mastery)
        }
      end

      private

      def normalize_element(element)
        return :physical if element.nil? || element.to_s.empty?

        element.to_s.downcase.to_sym
      end

      def extract_resistance_level(defender, skill_key)
        return 0 unless defender

        # Try passive_skill_level method (Character)
        if defender.respond_to?(:passive_skill_level)
          return defender.passive_skill_level(skill_key).to_i
        end

        # Try getting from character through participant
        if defender.respond_to?(:character) && defender.character
          return defender.character.passive_skill_level(skill_key).to_i
        end

        # Try passive_skills hash (NPC templates or raw data)
        if defender.respond_to?(:passive_skills) && defender.passive_skills.is_a?(Hash)
          return (defender.passive_skills[skill_key.to_s] || defender.passive_skills[skill_key]).to_i
        end

        # Try metadata for NPCs
        if defender.respond_to?(:metadata) && defender.metadata.is_a?(Hash)
          skills = defender.metadata["passive_skills"] || defender.metadata[:passive_skills]
          if skills.is_a?(Hash)
            return (skills[skill_key.to_s] || skills[skill_key]).to_i
          end
        end

        0
      end

      def extract_equipment_resistance(defender, element)
        return 0.0 unless defender

        # Get equipment bonuses if character has equipped items
        if defender.respond_to?(:equipped_items_resistance)
          return defender.equipped_items_resistance(element).to_f
        end

        # Try through character association
        if defender.respond_to?(:character) && defender.character.respond_to?(:equipped_items_resistance)
          return defender.character.equipped_items_resistance(element).to_f
        end

        0.0
      end
    end
  end
end
