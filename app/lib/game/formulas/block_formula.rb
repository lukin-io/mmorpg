# frozen_string_literal: true

module Game
  module Formulas
    # Purpose: Calculates block effectiveness when defender has blocking stance for attacked body part.
    #
    # Inputs:
    #   - attacker_body_part: String - the body part being attacked
    #   - defender_blocks: Array<Hash> - blocks selected by defender [{body_part:, action_key:}]
    #   - defender: Character or NPC with stats
    #   - attacker: Character or NPC (optional, for penetration calculation)
    #   - rng: Random instance for deterministic results
    #
    # Returns:
    #   Hash with :blocked (Boolean), :damage_reduction (Float 0-1), :partial (Boolean)
    #
    # Usage:
    #   formula = Game::Formulas::BlockFormula.new(rng: Random.new(123))
    #   result = formula.call(
    #     attacker_body_part: "head",
    #     defender_blocks: [{body_part: "head", action_key: "head_block"}],
    #     defender: warrior
    #   )
    #   # => { blocked: true, damage_reduction: 0.8, partial: false }
    #
    class BlockFormula
      BASE_BLOCK_CHANCE = 50 # 50% base block chance when blocking correct part
      BASE_DAMAGE_REDUCTION = 0.8 # Block reduces 80% damage

      # Block type effectiveness
      BLOCK_TYPE_EFFECTIVENESS = {
        "basic_block" => {chance: 0, reduction: 0.6},
        "shield_block" => {chance: 10, reduction: 0.75},
        "head_block" => {chance: 5, reduction: 0.7},
        "torso_block" => {chance: 5, reduction: 0.7},
        "stomach_block" => {chance: 5, reduction: 0.7},
        "legs_block" => {chance: 5, reduction: 0.7},
        "head_torso_block" => {chance: 0, reduction: 0.6},
        "full_block" => {chance: -10, reduction: 0.5}
      }.freeze

      # Magic shield blocks
      MAGIC_BLOCKS = {
        "magic_shield" => {chance: 20, reduction: 0.9, mana_cost: 20},
        "rainbow_barrier" => {chance: 30, reduction: 0.95, mana_cost: 40},
        "crystal_sphere" => {chance: 50, reduction: 1.0, mana_cost: 65}
      }.freeze

      def initialize(rng: Random.new)
        @rng = rng
      end

      # Calculate if attack is blocked and how much damage is reduced
      #
      # @param attacker_body_part [String] body part being attacked
      # @param defender_blocks [Array<Hash>] blocks selected by defender
      # @param defender [Character, NpcTemplate] defending combatant
      # @param attacker [Character, NpcTemplate] attacking combatant (optional)
      # @return [Hash] result with :blocked, :damage_reduction, :partial, :block_type
      def call(attacker_body_part:, defender_blocks:, defender:, attacker: nil)
        return not_blocked unless defender_blocks.present?

        # Find block covering the attacked body part
        covering_block = find_covering_block(attacker_body_part, defender_blocks)
        return not_blocked unless covering_block

        block_key = covering_block[:action_key] || covering_block["action_key"] || "basic_block"

        # Check for magic blocks first
        if MAGIC_BLOCKS.key?(block_key)
          return calculate_magic_block(block_key, defender, attacker)
        end

        # Calculate physical block chance
        block_chance = BASE_BLOCK_CHANCE

        # Apply block type modifier
        block_config = BLOCK_TYPE_EFFECTIVENESS.fetch(block_key, {chance: 0, reduction: 0.6})
        block_chance += block_config[:chance]

        # Apply defender's stats
        block_chance = apply_defender_stats(block_chance, defender)

        # Apply attacker's penetration stats
        block_chance = apply_attacker_penetration(block_chance, attacker) if attacker

        # Apply passive skill bonus
        block_chance = apply_block_skill(block_chance, defender)

        # Clamp block chance
        block_chance = block_chance.clamp(10.0, 90.0)

        # Roll for block
        roll = @rng.rand(100)
        blocked = roll < block_chance

        if blocked
          damage_reduction = block_config[:reduction]

          # Apply shield bonus if using shield
          if defender.respond_to?(:has_shield?) && defender.has_shield?
            damage_reduction = [damage_reduction + 0.1, 0.95].min
          end

          {
            blocked: true,
            damage_reduction: damage_reduction,
            partial: false,
            block_type: block_key,
            roll: roll,
            chance: block_chance.round(1)
          }
        else
          # Partial block - still reduces some damage
          {
            blocked: false,
            damage_reduction: 0.2, # 20% damage reduction on failed block
            partial: true,
            block_type: block_key,
            roll: roll,
            chance: block_chance.round(1)
          }
        end
      end

      private

      def find_covering_block(body_part, blocks)
        blocks.find do |block|
          block_parts = block[:body_parts] || block["body_parts"] ||
            [block[:body_part] || block["body_part"]]
          block_parts.include?(body_part)
        end
      end

      def calculate_magic_block(block_key, defender, attacker)
        magic_config = MAGIC_BLOCKS[block_key]
        block_chance = BASE_BLOCK_CHANCE + magic_config[:chance]

        # Magic blocks scale with intelligence
        if defender.respond_to?(:stats)
          intel = extract_stat(defender, :intelligence)
          block_chance += (intel * 0.4)
        end

        # Apply spell mastery skill
        if defender.respond_to?(:passive_skill_level)
          spell_mastery = defender.passive_skill_level(:spell_mastery)
          block_chance += (spell_mastery / 100.0 * 15)
        end

        block_chance = block_chance.clamp(20.0, 95.0)
        roll = @rng.rand(100)
        blocked = roll < block_chance

        {
          blocked: blocked,
          damage_reduction: blocked ? magic_config[:reduction] : 0.1,
          partial: !blocked,
          block_type: block_key,
          magic_block: true,
          mana_cost: magic_config[:mana_cost],
          roll: roll,
          chance: block_chance.round(1)
        }
      end

      def apply_defender_stats(block_chance, defender)
        # Strength helps with physical blocking
        strength = extract_stat(defender, :strength)
        block_chance += (strength * 0.2)

        # Dexterity helps with reaction time
        dexterity = extract_stat(defender, :dexterity)
        block_chance += (dexterity * 0.15)

        block_chance
      end

      def apply_attacker_penetration(block_chance, attacker)
        # Attacker strength can penetrate blocks
        strength = extract_stat(attacker, :strength)
        block_chance -= (strength * 0.1)

        block_chance
      end

      def apply_block_skill(block_chance, defender)
        return block_chance unless defender.respond_to?(:passive_skill_level)

        block_mastery = defender.passive_skill_level(:block_mastery)
        block_chance + (block_mastery / 100.0 * 25) # Up to 25% from skill
      end

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

      def not_blocked
        {blocked: false, damage_reduction: 0, partial: false, block_type: nil}
      end
    end
  end
end
