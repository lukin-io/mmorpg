# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Calculates hit chance for combat attacks based on attacker accuracy and defender evasion.
    #
    # Inputs:
    #   - attacker: Character or NPC with stats (accuracy, dexterity)
    #   - defender: Character or NPC with stats (evasion, agility)
    #   - body_part: String - target body part ("head", "torso", "stomach", "legs")
    #   - action_key: String - attack type ("simple", "aimed", etc.)
    #   - rng: Random instance for deterministic results (default: Random.new)
    #
    # Returns:
    #   Hash with :hit (Boolean), :roll (Integer), :chance (Float), :dodge (Boolean)
    #
    # Usage:
    #   formula = Game::Formulas::HitFormula.new(rng: Random.new(123))
    #   result = formula.call(attacker: warrior, defender: rogue, body_part: "head")
    #   # => { hit: true, roll: 42, chance: 85.5, dodge: false }
    #
    class HitFormula
      BASE_HIT_CHANCE = 85 # 85% base hit chance
      BODY_PART_MODIFIERS = {
        "head" => -10,    # Harder to hit
        "torso" => 0,     # Standard
        "stomach" => 5,   # Slightly easier
        "legs" => -5      # Somewhat harder
      }.freeze

      ATTACK_TYPE_MODIFIERS = {
        "simple" => 0,
        "aimed" => 15,      # More accurate
        "power" => -10,     # Less accurate but more damage
        "quick" => 5        # Slightly more accurate
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Calculate hit chance and determine if attack hits
      #
      # @param attacker [Character, NpcTemplate] the attacking combatant
      # @param defender [Character, NpcTemplate] the defending combatant
      # @param body_part [String] target body part
      # @param action_key [String] attack type key
      # @return [Hash] result with :hit, :roll, :chance, :dodge keys
      def call(attacker:, defender:, body_part: "torso", action_key: "simple")
        # Calculate base hit chance
        hit_chance = BASE_HIT_CHANCE

        # Apply attacker accuracy bonus
        attacker_accuracy = extract_stat(attacker, :accuracy)
        hit_chance += (attacker_accuracy * 0.5)

        # Apply attacker dexterity bonus
        attacker_dexterity = extract_stat(attacker, :dexterity)
        hit_chance += (attacker_dexterity * 0.3)

        # Apply defender evasion penalty
        defender_evasion = extract_stat(defender, :evasion)
        hit_chance -= (defender_evasion * 0.4)

        # Apply defender agility penalty
        defender_agility = extract_stat(defender, :agility)
        hit_chance -= (defender_agility * 0.2)

        # Apply body part modifier
        hit_chance += BODY_PART_MODIFIERS.fetch(body_part, 0)

        # Apply attack type modifier
        hit_chance += ATTACK_TYPE_MODIFIERS.fetch(action_key, 0)

        # Apply passive skill bonuses
        hit_chance = apply_skill_bonuses(hit_chance, attacker, defender)

        # Clamp hit chance between 5% and 95%
        hit_chance = hit_chance.clamp(5.0, 95.0)

        # Roll for hit
        roll = @rng.rand(100)
        hit = roll < hit_chance

        # Check for dodge (separate roll if hit succeeded)
        dodge = false
        if hit
          dodge_chance = calculate_dodge_chance(defender)
          dodge_roll = @rng.rand(100)
          dodge = dodge_roll < dodge_chance
        end

        {
          hit: hit && !dodge,
          roll: roll,
          chance: hit_chance.round(1),
          dodge: dodge,
          dodge_chance: dodge ? calculate_dodge_chance(defender).round(1) : 0
        }
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

      def calculate_dodge_chance(defender)
        base_dodge = 5 # 5% base dodge
        agility_bonus = extract_stat(defender, :agility) * 0.3
        evasion_bonus = extract_stat(defender, :evasion) * 0.2

        # Apply evasion passive skill if character
        if defender.respond_to?(:passive_skill_level)
          evasion_skill = defender.passive_skill_level(:evasion)
          base_dodge += (evasion_skill / 100.0 * 20) # Up to 20% from skill
        end

        (base_dodge + agility_bonus + evasion_bonus).clamp(0.0, 40.0)
      end

      def apply_skill_bonuses(hit_chance, attacker, defender)
        # Apply attacker's combat skills
        if attacker.respond_to?(:passive_skill_level)
          melee_skill = attacker.passive_skill_level(:melee_combat)
          hit_chance += (melee_skill / 100.0 * 10) # Up to 10% from melee skill

          ranged_skill = attacker.passive_skill_level(:ranged_combat)
          hit_chance += (ranged_skill / 100.0 * 5) # Up to 5% from ranged skill
        end

        # Apply defender's evasion skill
        if defender.respond_to?(:passive_skill_level)
          evasion_skill = defender.passive_skill_level(:evasion)
          hit_chance -= (evasion_skill / 100.0 * 8) # Up to -8% from evasion
        end

        hit_chance
      end
    end
  end
end
