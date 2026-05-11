# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Unified damage calculation for both PvE and PvP combat.
    # Provides deterministic, seeded damage calculations.
    #
    # Inputs:
    #   - attacker: Character or NPC with attack stats
    #   - defender: Character or NPC with defense stats
    #   - rng: Random instance for deterministic results
    #   - options: Hash with :is_defending, :is_critical, :damage_multiplier
    #
    # Returns:
    #   Integer - final damage value (minimum 1)
    #
    # Usage:
    #   formula = Game::Formulas::CombatDamageFormula.new(rng: Random.new(123))
    #   damage = formula.call(warrior, goblin)
    #   # => 14
    #
    #   # With options
    #   damage = formula.call(warrior, goblin, is_defending: true, is_critical: true)
    #   # => 10 (reduced by defense, increased by crit)
    #
    class CombatDamageFormula
      DEFENSE_MULTIPLIER_DEFENDING = 1.5
      DEFENSE_DIVISOR = 2
      CRITICAL_MULTIPLIER = 1.5
      VARIANCE_RANGE = 1..5
      MIN_DAMAGE = 1

      attr_reader :rng

      def initialize(rng: Random.new(1))
        @rng = rng
      end

      # Calculate damage dealt
      #
      # @param attacker [Character, NPC] the attacking entity
      # @param defender [Character, NPC] the defending entity
      # @param is_defending [Boolean] whether defender is in defensive stance
      # @param is_critical [Boolean] whether this is a critical hit
      # @param damage_multiplier [Float] additional multiplier (e.g., 1.3 for aimed attacks)
      # @return [Integer] final damage
      def call(attacker, defender, is_defending: false, is_critical: false, damage_multiplier: 1.0)
        base_attack = attack_power(attacker)
        base_defense = defense_power(defender)

        # Defense is more effective when actively defending
        defense_mult = is_defending ? DEFENSE_MULTIPLIER_DEFENDING : 1.0
        effective_defense = (base_defense * defense_mult).to_i

        # Base damage = attack - (defense / 2)
        damage = base_attack - (effective_defense / DEFENSE_DIVISOR)

        # Add variance
        damage += rng.rand(VARIANCE_RANGE)

        # Apply damage multiplier (aimed attacks, skills, etc.)
        damage = (damage * damage_multiplier).to_i

        # Apply critical hit multiplier
        damage = (damage * CRITICAL_MULTIPLIER).to_i if is_critical

        # Minimum damage
        [damage, MIN_DAMAGE].max
      end

      # Check if attack is a critical hit
      #
      # @param attacker [Character, NPC] the attacking entity
      # @return [Boolean]
      def critical_hit?(attacker)
        chance = crit_chance(attacker)
        rng.rand(100) < chance
      end

      # Get attack power from entity
      #
      # @param entity [Character, NPC] the entity
      # @return [Integer]
      def attack_power(entity)
        return entity.attack_power if supports_method?(entity, :attack_power)
        return entity.stats.get(:attack_power) if supports_method?(entity, :stats)
        return entity.combat_stat(:attack) if supports_method?(entity, :combat_stat)

        # Default for entities without stats
        10
      end

      # Get defense power from entity
      #
      # @param entity [Character, NPC] the entity
      # @return [Integer]
      def defense_power(entity)
        return entity.defense if supports_method?(entity, :defense)
        return entity.defense_value if supports_method?(entity, :defense_value)
        return entity.stats.get(:defense) if supports_method?(entity, :stats)
        return entity.combat_stat(:defense) if supports_method?(entity, :combat_stat)

        # Default for entities without stats
        5
      end

      # Get critical hit chance from entity
      #
      # @param entity [Character, NPC] the entity
      # @return [Integer] percentage (0-100)
      def crit_chance(entity)
        return entity.critical_chance if supports_method?(entity, :critical_chance)
        return entity.stats.get(:critical_chance) if supports_method?(entity, :stats)
        return entity.combat_stat(:crit_chance) if supports_method?(entity, :combat_stat)

        # Default crit chance
        5
      end

      private

      def supports_method?(entity, method_name)
        entity.public_methods.include?(method_name.to_sym)
      end
    end
  end
end
