# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Calculates critical hit chance and damage multiplier for combat attacks.
    #
    # Inputs:
    #   - attacker: Character or NPC with stats (luck, critical_chance)
    #   - defender: Character or NPC with stats (luck - reduces crit chance)
    #   - body_part: String - target body part affects crit chance
    #   - action_key: String - attack type affects crit chance
    #   - rng: Random instance for deterministic results
    #
    # Returns:
    #   Hash with :critical (Boolean), :multiplier (Float), :roll (Integer), :chance (Float)
    #
    # Usage:
    #   formula = Game::Formulas::CriticalFormula.new(rng: Random.new(123))
    #   result = formula.call(attacker: rogue, defender: warrior, body_part: "head")
    #   # => { critical: true, multiplier: 1.5, roll: 8, chance: 15.0 }
    #
    class CriticalFormula
      BASE_CRIT_CHANCE = 10 # 10% base critical chance
      BASE_CRIT_MULTIPLIER = 1.5

      # Body part crit modifiers
      BODY_PART_CRIT_MODIFIERS = {
        "head" => 5,     # +5% crit chance on head
        "torso" => 0,    # Standard
        "stomach" => 2,  # Slightly higher
        "legs" => -3     # Lower crit chance
      }.freeze

      # Attack type crit modifiers
      ATTACK_TYPE_CRIT_MODIFIERS = {
        "simple" => 0,
        "aimed" => 10,    # Aimed attacks crit more often
        "power" => 5,     # Power attacks have decent crit
        "quick" => -5     # Quick attacks crit less
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Calculate if attack is critical and the damage multiplier
      #
      # @param attacker [Character, NpcTemplate] attacking combatant
      # @param defender [Character, NpcTemplate] defending combatant
      # @param body_part [String] target body part
      # @param action_key [String] attack type
      # @return [Hash] result with :critical, :multiplier, :roll, :chance
      def call(attacker:, defender:, body_part: "torso", action_key: "simple")
        crit_chance = BASE_CRIT_CHANCE

        # Apply attacker luck bonus
        attacker_luck = extract_stat(attacker, :luck)
        crit_chance += (attacker_luck * 0.3)

        # Apply attacker critical_chance stat if exists
        attacker_crit = extract_stat(attacker, :critical_chance)
        crit_chance += attacker_crit

        # Apply defender luck penalty (reduces incoming crits)
        defender_luck = extract_stat(defender, :luck)
        crit_chance -= (defender_luck * 0.15)

        # Apply body part modifier
        crit_chance += BODY_PART_CRIT_MODIFIERS.fetch(body_part, 0)

        # Apply attack type modifier
        crit_chance += ATTACK_TYPE_CRIT_MODIFIERS.fetch(action_key, 0)

        # Apply passive skill bonuses
        crit_chance = apply_skill_bonuses(crit_chance, attacker)

        # Clamp crit chance
        crit_chance = crit_chance.clamp(1.0, 50.0)

        # Roll for critical
        roll = @rng.rand(100)
        critical = roll < crit_chance

        # Calculate multiplier
        multiplier = calculate_multiplier(critical, attacker, body_part)

        {
          critical: critical,
          multiplier: multiplier,
          roll: roll,
          chance: crit_chance.round(1)
        }
      end

      # Calculate only the multiplier (for cases where crit is already determined)
      #
      # @param attacker [Character, NpcTemplate] attacking combatant
      # @param body_part [String] target body part
      # @return [Float] damage multiplier
      def multiplier_for(attacker:, body_part: "torso")
        multiplier = BASE_CRIT_MULTIPLIER

        # Bonus from critical strikes skill
        if attacker.respond_to?(:passive_skill_level)
          crit_skill = attacker.passive_skill_level(:critical_strikes)
          multiplier += (crit_skill / 100.0 * 0.5) # Up to +0.5x from skill
        end

        # Head crits deal extra damage
        multiplier += 0.2 if body_part == "head"

        multiplier.round(2)
      end

      private

      def extract_stat(combatant, stat_name)
        return 0 unless combatant

        if combatant.respond_to?(:stats) && combatant.stats.respond_to?(:get)
          combatant.stats.get(stat_name).to_i
        elsif combatant.respond_to?(stat_name)
          combatant.public_send(stat_name).to_i
        elsif combatant.respond_to?(:metadata) && combatant.metadata.is_a?(Hash)
          combatant.metadata[stat_name.to_s].to_i
        else
          0
        end
      end

      def apply_skill_bonuses(crit_chance, attacker)
        return crit_chance unless attacker.respond_to?(:passive_skill_level)

        # Critical strikes skill
        crit_skill = attacker.passive_skill_level(:critical_strikes)
        crit_chance + (crit_skill / 100.0 * 15) # Up to 15% from skill
      end

      def calculate_multiplier(critical, attacker, body_part)
        return 1.0 unless critical

        multiplier_for(attacker: attacker, body_part: body_part)
      end
    end
  end
end
