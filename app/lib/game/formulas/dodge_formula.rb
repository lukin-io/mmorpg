# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Calculates dodge/evasion chance for combat - allows complete attack avoidance.
    #
    # Inputs:
    #   - defender: Character or NPC with stats (agility, evasion, luck)
    #   - attacker: Character or NPC with stats (accuracy, dexterity)
    #   - body_part: String - target body part (some parts harder to dodge)
    #   - action_key: String - attack type (aimed attacks harder to dodge)
    #   - rng: Random instance for deterministic results
    #
    # Returns:
    #   Hash with :dodged (Boolean), :roll (Integer), :chance (Float)
    #
    # Usage:
    #   formula = Game::Formulas::DodgeFormula.new(rng: Random.new(123))
    #   result = formula.call(defender: rogue, attacker: warrior, body_part: "head")
    #   # => { dodged: true, roll: 5, chance: 18.5 }
    #
    class DodgeFormula
      BASE_DODGE_CHANCE = 5 # 5% base dodge chance

      # Body part dodge modifiers (easier/harder to dodge based on target)
      BODY_PART_DODGE_MODIFIERS = {
        "head" => 3,     # Easier to dodge head attacks (duck)
        "torso" => 0,    # Standard
        "stomach" => -2, # Slightly harder to dodge
        "legs" => -5     # Very hard to dodge leg attacks
      }.freeze

      # Attack type dodge modifiers
      ATTACK_TYPE_DODGE_MODIFIERS = {
        "simple" => 0,
        "aimed" => -10,   # Aimed attacks much harder to dodge
        "power" => 5,     # Power attacks telegraphed, easier to dodge
        "quick" => -3     # Quick attacks slightly harder to dodge
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Calculate if defender dodges the attack
      #
      # @param defender [Character, NpcTemplate] defending combatant
      # @param attacker [Character, NpcTemplate] attacking combatant
      # @param body_part [String] target body part
      # @param action_key [String] attack type
      # @return [Hash] result with :dodged, :roll, :chance
      def call(defender:, attacker:, body_part: "torso", action_key: "simple")
        dodge_chance = BASE_DODGE_CHANCE

        # Apply defender agility bonus (primary dodge stat)
        defender_agility = extract_stat(defender, :agility)
        dodge_chance += (defender_agility * 0.4)

        # Apply defender evasion stat
        defender_evasion = extract_stat(defender, :evasion)
        dodge_chance += (defender_evasion * 0.3)

        # Apply defender luck bonus
        defender_luck = extract_stat(defender, :luck)
        dodge_chance += (defender_luck * 0.1)

        # Apply attacker accuracy penalty to dodge
        attacker_accuracy = extract_stat(attacker, :accuracy)
        dodge_chance -= (attacker_accuracy * 0.25)

        # Apply attacker dexterity penalty
        attacker_dexterity = extract_stat(attacker, :dexterity)
        dodge_chance -= (attacker_dexterity * 0.15)

        # Apply body part modifier
        dodge_chance += BODY_PART_DODGE_MODIFIERS.fetch(body_part, 0)

        # Apply attack type modifier
        dodge_chance += ATTACK_TYPE_DODGE_MODIFIERS.fetch(action_key, 0)

        # Apply passive skill bonuses
        dodge_chance = apply_skill_bonuses(dodge_chance, defender, attacker)

        # Apply equipment bonuses
        dodge_chance = apply_equipment_bonuses(dodge_chance, defender)

        # Clamp dodge chance (can't exceed 40% or go below 0%)
        dodge_chance = dodge_chance.clamp(0.0, 40.0)

        # Roll for dodge
        roll = @rng.rand(100)
        dodged = roll < dodge_chance

        {
          dodged: dodged,
          roll: roll,
          chance: dodge_chance.round(1)
        }
      end

      # Get raw dodge chance without rolling (for UI display)
      #
      # @param defender [Character, NpcTemplate] defending combatant
      # @return [Float] dodge chance percentage
      def dodge_chance_for(defender:)
        dodge_chance = BASE_DODGE_CHANCE

        defender_agility = extract_stat(defender, :agility)
        dodge_chance += (defender_agility * 0.4)

        defender_evasion = extract_stat(defender, :evasion)
        dodge_chance += (defender_evasion * 0.3)

        # Apply evasion skill
        if defender.respond_to?(:passive_skill_level)
          evasion_skill = defender.passive_skill_level(:evasion)
          dodge_chance += (evasion_skill / 100.0 * 20)
        end

        dodge_chance.clamp(0.0, 40.0).round(1)
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

      def apply_skill_bonuses(dodge_chance, defender, attacker)
        # Defender evasion skill
        if defender.respond_to?(:passive_skill_level)
          evasion_skill = defender.passive_skill_level(:evasion)
          dodge_chance += (evasion_skill / 100.0 * 20) # Up to 20% from skill
        end

        # Attacker melee skill reduces dodge chance
        if attacker.respond_to?(:passive_skill_level)
          melee_skill = attacker.passive_skill_level(:melee_combat)
          dodge_chance -= (melee_skill / 100.0 * 8) # Up to -8% from attacker skill
        end

        dodge_chance
      end

      def apply_equipment_bonuses(dodge_chance, defender)
        # Light armor bonus
        if defender.respond_to?(:armor_type)
          case defender.armor_type
          when "light", "cloth"
            dodge_chance += 5
          when "medium", "leather"
            dodge_chance += 2
          when "heavy", "plate"
            dodge_chance -= 5
          end
        end

        dodge_chance
      end
    end
  end
end
