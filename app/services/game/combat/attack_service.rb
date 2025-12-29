# frozen_string_literal: true

module Game
  module Combat
    # Purpose: Legacy service for simple attack resolution.
    # Now delegates to TurnResolver with battle context.
    #
    # Note: For full combat, use TurnResolver directly with a battle.
    # This service provides backward compatibility for simple attacks.
    #
    class AttackService
      # Result struct compatible with legacy expectations
      LegacyResult = Struct.new(
        :log, :hp_changes, :effects, :battle,
        keyword_init: true
      )

      def initialize(turn_resolver: TurnResolver)
        @turn_resolver_class = turn_resolver
      end

      # Perform a simple attack from attacker to defender
      #
      # @param attacker [Character, OpenStruct] the attacking entity
      # @param defender [Character, OpenStruct] the defending entity
      # @param action [String] the action name
      # @param rng_seed [Integer] seed for deterministic results
      # @param battle [Battle, nil] optional battle context
      # @param ability [Ability, nil] optional ability being used
      # @return [LegacyResult] attack result
      def call(attacker:, defender:, action:, rng_seed: 1, battle: nil, ability: nil)
        rng = Random.new(rng_seed)

        # If we have a real battle, use TurnResolver
        if battle&.is_a?(Battle)
          return resolve_with_battle(battle, attacker, action, rng, ability)
        end

        # For legacy/mock usage without real battle, calculate damage directly
        resolve_without_battle(attacker, defender, action, rng, ability)
      end

      private

      attr_reader :turn_resolver_class

      def resolve_with_battle(battle, attacker, action, rng, ability)
        # Set up pending attack on participant
        participant = battle.battle_participants.find_by(character: attacker)
        if participant
          participant.update!(
            pending_attacks: [{ "body_part" => "torso", "attack_type" => "simple" }]
          )
        end

        # Resolve turn
        resolver = turn_resolver_class.new(battle, rng: rng)
        result = resolver.resolve!

        # Create combat log entry
        battle.combat_log_entries.create!(
          round_number: battle.turn_number,
          sequence: 1,
          log_type: "attack",
          message: result.log_entries.first&.dig(:message) || "#{attacker.name} attacks with #{action}",
          actor_id: attacker.id,
          actor_type: "Character",
          payload: { action: action, ability: ability&.name }
        )

        # Advance turn
        battle.increment!(:turn_number)

        LegacyResult.new(
          log: result.log_entries.map { |e| e[:message] },
          hp_changes: result.hp_changes,
          effects: extract_ability_effects(ability),
          battle: battle
        )
      end

      def resolve_without_battle(attacker, defender, action, rng, ability)
        # Calculate damage using formulas
        damage = calculate_damage(attacker, defender, rng)
        is_crit = check_critical(attacker, rng)

        if is_crit
          damage = (damage * 1.5).to_i
        end

        # Apply ability bonus
        if ability
          damage += ability.effects&.dig("damage").to_i
        end

        log_message = build_log_message(attacker, defender, action, damage, is_crit)

        LegacyResult.new(
          log: [log_message],
          hp_changes: { defender: -damage },
          effects: extract_ability_effects(ability),
          battle: nil
        )
      end

      def calculate_damage(attacker, defender, rng)
        attack = extract_stat(attacker, :attack)
        defense = extract_stat(defender, :defense)

        base = attack - (defense / 2)
        variance = rng.rand(-2..2)
        [base + variance, 1].max
      end

      def check_critical(attacker, rng)
        crit_chance = extract_stat(attacker, :crit_chance)
        rng.rand(100) < crit_chance
      end

      def extract_stat(entity, stat)
        if entity.respond_to?(:stats) && entity.stats.respond_to?(:get)
          entity.stats.get(stat).to_i
        elsif entity.respond_to?(stat)
          entity.send(stat).to_i
        else
          10 # default
        end
      end

      def build_log_message(attacker, defender, action, damage, is_crit)
        crit_text = is_crit ? " CRIT!" : ""
        "#{attacker.name} uses #{action} on #{defender.name} for #{damage} damage#{crit_text}"
      end

      def extract_ability_effects(ability)
        return {} unless ability

        {
          damage_bonus: ability.effects&.dig("damage").to_i,
          status: ability.effects&.dig("status"),
          buffs: ability.effects&.dig("buffs") || [],
          debuffs: ability.effects&.dig("debuffs") || []
        }
      end
    end
  end
end
