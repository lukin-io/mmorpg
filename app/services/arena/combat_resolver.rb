# frozen_string_literal: true

module Arena
  # Resolves one Neverlands-style arena attack.
  #
  # The captured client flow makes AP/cost data fight-specific, then resolves a
  # submitted turn into clear outcomes: miss, dodge, block, hit, critical hit,
  # and damage. This service keeps that result shape explicit so player, team,
  # and NPC fights do not drift into separate combat engines.
  class CombatResolver
    BODY_PART_HIT_MODIFIERS = {
      "head" => -10,
      "torso" => 0,
      "stomach" => 5,
      "legs" => -5
    }.freeze

    BODY_PART_DODGE_MODIFIERS = {
      "head" => 3,
      "torso" => 0,
      "stomach" => -2,
      "legs" => -5
    }.freeze

    BODY_PART_BLOCK_MODIFIERS = {
      "head" => -5,
      "torso" => 5,
      "stomach" => 2,
      "legs" => -3
    }.freeze

    BODY_PART_DAMAGE_MULTIPLIERS = {
      "head" => 1.3,
      "torso" => 1.0,
      "stomach" => 1.1,
      "legs" => 0.9
    }.freeze

    BASE_HIT_CHANCE = 85
    BASE_DODGE_CHANCE = 5
    BASE_BLOCK_CHANCE = 45
    BASE_CRIT_CHANCE = 10
    CRITICAL_MULTIPLIER = 2.0
    DEFENSE_DIVISOR = 2
    MIN_DAMAGE = 0

    attr_reader :match, :rng

    def initialize(match:, rng: Random.new)
      @match = match
      @rng = rng
    end

    def resolve_physical_attack(attacker_participation:, defender_participation:, action_key:, body_part:, block: nil)
      @attributes = {}
      action_key = action_key.to_s
      body_part = body_part.to_s

      element = Game::Combat::ActionCatalog.attack_config(action_key)["element"]
      if element.present?
        return resolve_magic_attack(attacker_participation, defender_participation, action_key, body_part, block, element)
      end

      hit = hit_result(attacker_participation, defender_participation, action_key, body_part)
      return outcome(:miss, action_key:, body_part:, hit:) unless hit[:hit]

      dodge = dodge_result(attacker_participation, defender_participation, action_key, body_part)
      if dodge[:dodged]
        # A critical attempt can be dodged without dealing damage. The source
        # establishes that outcome, not its private random-roll ordering.
        critical = critical_result(attacker_participation, defender_participation, action_key, body_part)
        return outcome(:dodge, action_key:, body_part:, hit:, dodge:, critical:)
      end

      block_result_data = {}
      if block_covers?(block, body_part)
        block_result_data = block_result(attacker_participation, defender_participation, block, body_part)
        if block_result_data[:blocked]
          return outcome(
            :blocked,
            action_key:,
            body_part:,
            hit:,
            dodge:,
            block: block.merge(
              "attempted" => true,
              "blocked" => true,
              "damage_reduction" => 1.0,
              "roll" => block_result_data[:roll],
              "chance" => block_result_data[:chance]
            )
          )
        end
      end

      critical = critical_result(attacker_participation, defender_participation, action_key, body_part)
      damage = damage_amount(attacker_participation, defender_participation, action_key, body_part, critical:)

      block_data = block_result_data.present? ? block.merge(
        "attempted" => true,
        "blocked" => false,
        "roll" => block_result_data[:roll],
        "chance" => block_result_data[:chance]
      ) : {}

      outcome(:hit, action_key:, body_part:, hit:, dodge:, block: block_data, critical:, damage:)
    end

    def attack_power(participation)
      Game::Combat::Calibration.attack(attributes(participation)).round
    end

    def defense_power(participation)
      attributes(participation).fetch(:armor, 0)
    end

    private

    def outcome(type, action_key:, body_part:, hit: {}, dodge: {}, block: {}, critical: {}, damage: 0)
      {
        outcome: type,
        hit: type == :hit,
        miss: type == :miss,
        dodge: type == :dodge,
        blocked: type == :blocked,
        critical: critical.fetch(:critical, false),
        damage: damage.to_i,
        action_key:,
        body_part:,
        hit_roll: hit[:roll],
        hit_chance: hit[:chance],
        dodge_roll: dodge[:roll],
        dodge_chance: dodge[:chance],
        crit_roll: critical[:roll],
        crit_chance: critical[:chance],
        block_key: block["action_key"],
        block_table: block["block_table"],
        block_attempted: block["attempted"] == true,
        block_success: block["blocked"] == true,
        block_roll: block["roll"],
        block_chance: block["chance"]
      }
    end

    def hit_result(attacker, defender, action_key, body_part)
      offense = stat(attacker, :dexterity) * 5 + stat(attacker, :accuracy)
      defense = stat(defender, :dexterity) * 2 + stat(defender, :evasion)
      chance = (BASE_HIT_CHANCE + opposed(offense, defense, scale: 15) +
        Game::Combat::ActionCatalog.attack_hit_bonus(action_key) +
        BODY_PART_HIT_MODIFIERS.fetch(body_part, 0)).clamp(5.0, 95.0)

      roll = rng.rand(100)
      {hit: roll < chance, roll:, chance: chance.round(1)}
    end

    def dodge_result(attacker, defender, action_key, body_part)
      offense = stat(attacker, :dexterity) * 5 + stat(attacker, :accuracy)
      defense = stat(defender, :dexterity) * 5 + stat(defender, :evasion)
      chance = (BASE_DODGE_CHANCE + opposed(defense, offense) +
        BODY_PART_DODGE_MODIFIERS.fetch(body_part, 0) - (action_key == "aimed" ? 5 : 0)).clamp(0.0, 60.0)

      roll = rng.rand(100)
      {dodged: roll < chance, roll:, chance: chance.round(1)}
    end

    def critical_result(attacker, defender, action_key, body_part)
      offense = stat(attacker, :luck) * 5 + stat(attacker, :crushing)
      defense = stat(defender, :luck) * 5 + stat(defender, :fortitude)
      chance = (BASE_CRIT_CHANCE + opposed(offense, defense, scale: 75) +
        (action_key == "aimed" ? 10 : 0) + (body_part == "head" ? 5 : 0)).clamp(1.0, 85.0)

      roll = rng.rand(100)
      {critical: roll < chance, roll:, chance: chance.round(1)}
    end

    def block_result(attacker, defender, block, body_part)
      covered_parts = Array(block["body_parts"]).map(&:to_s)
      offense = stat(attacker, :accuracy) + stat(attacker, :penetration) * 2 + stat(attacker, :dexterity) * 3
      defense = defense_power(defender) + stat(defender, :dexterity) * 3
      chance = (BASE_BLOCK_CHANCE + opposed(defense, offense) +
        BODY_PART_BLOCK_MODIFIERS.fetch(body_part, 0) - [covered_parts.size - 1, 0].max * 4).clamp(5.0, 95.0)

      roll = rng.rand(100)
      {blocked: roll < chance, roll:, chance: chance.round(1)}
    end

    def damage_amount(attacker, defender, action_key, body_part, critical:)
      variation = Game::Combat::Calibration.config.fetch("damage_variance")
      variance = 1 + (rng.rand(1..5) - 3) / 2.0 * variation
      Game::Combat::Calibration.damage(
        attacker: attributes(attacker), defender: attributes(defender),
        action_multiplier: Game::Combat::ActionCatalog.attack_damage_multiplier(action_key),
        body_multiplier: BODY_PART_DAMAGE_MULTIPLIERS.fetch(body_part, 1.0),
        critical: critical[:critical], variance:
      )
    end

    # The captured Spirit Arrow opener spends 5 MP and can crit for 10.
    # Magic ignores physical armor; Knowledge, elemental skill/resistance and
    # a committed magic barrier govern the same persisted strike pipeline.
    def resolve_magic_attack(attacker, defender, action_key, body_part, block, element)
      hit = hit_result(attacker, defender, action_key, body_part)
      return outcome(:miss, action_key:, body_part:, hit:).merge(element:) unless hit[:hit]

      critical = critical_result(attacker, defender, action_key, body_part)
      mana = Game::Combat::ActionCatalog.attack_mana_cost(action_key)
      knowledge = [stat(attacker, :knowledge), 1].max
      skill = attacker.character&.passive_skill_level("#{element}_magic").to_i
      resistance = defender.character&.passive_skill_level("#{element}_magic_resistance").to_i +
        defender.character&.elemental_resistance_percent(element).to_f
      base = mana * (1 + (knowledge - 1) / 20.0) * (1 + skill / 100.0)
      base *= action_key == "mind_blast" ? 1.35 : 1.0
      base *= 1 - (resistance / 200.0).clamp(0, 0.75)
      reduction = block && block["block_table"] == "magic" ? {"magic_shield" => 0.2, "rainbow_barrier" => 0.45, "crystal_sphere" => 0.65}.fetch(block["action_key"], 0) : 0
      damage = (base * (1 - reduction) * (critical[:critical] ? CRITICAL_MULTIPLIER : 1)).round
      outcome(:hit, action_key:, body_part:, hit:, critical:, damage:).merge(element:, barrier_reduction: reduction)
    end

    def block_covers?(block, body_part)
      return false if block.blank?

      Array(block["body_parts"]).map(&:to_s).include?(body_part)
    end

    def stat(participation, stat_name)
      attributes(participation).fetch(stat_name, 0).to_f
    end

    def attributes(participation)
      @attributes ||= {}
      @attributes[participation.id] ||= CombatAttributes.for(participation)
    end

    def opposed(left, right, scale: 35.0)
      Game::Combat::Calibration.opposed(left, right, scale:)
    end
  end
end
