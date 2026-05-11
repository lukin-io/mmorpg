# frozen_string_literal: true

module Arena
  # Resolves one Neverlands-style arena attack.
  #
  # The captured client flow makes AP/cost data fight-specific, then resolves a
  # submitted turn into clear outcomes: miss, dodge, block, hit, critical hit,
  # and damage. This service keeps that result shape explicit so arena PvP and
  # NPC fights do not drift into separate combat engines.
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

    BODY_PART_DAMAGE_MULTIPLIERS = {
      "head" => 1.3,
      "torso" => 1.0,
      "stomach" => 1.1,
      "legs" => 0.9
    }.freeze

    BASE_HIT_CHANCE = 85
    BASE_DODGE_CHANCE = 5
    BASE_CRIT_CHANCE = 10
    CRITICAL_MULTIPLIER = 1.5
    DEFENSE_DIVISOR = 2
    MIN_DAMAGE = 0

    attr_reader :match, :rng

    def initialize(match:, rng: Random.new)
      @match = match
      @rng = rng
    end

    def resolve_physical_attack(attacker_participation:, defender_participation:, action_key:, body_part:, block: nil)
      action_key = action_key.to_s
      body_part = body_part.to_s

      hit = hit_result(attacker_participation, defender_participation, action_key, body_part)
      return outcome(:miss, action_key:, body_part:, hit:) unless hit[:hit]

      dodge = dodge_result(attacker_participation, defender_participation, action_key, body_part)
      return outcome(:dodge, action_key:, body_part:, hit:, dodge:) if dodge[:dodged]

      if block_covers?(block, body_part)
        return outcome(
          :blocked,
          action_key:,
          body_part:,
          hit:,
          dodge:,
          block: block.merge("blocked" => true, "damage_reduction" => 1.0)
        )
      end

      critical = critical_result(attacker_participation, defender_participation, action_key, body_part)
      damage = damage_amount(attacker_participation, defender_participation, action_key, body_part, critical:)

      outcome(:hit, action_key:, body_part:, hit:, dodge:, critical:, damage:)
    end

    def attack_power(participation)
      if participation.npc?
        npc_stats(participation)[:attack].to_i
      else
        participation.character&.attack_power.to_i
      end
    end

    def defense_power(participation)
      if participation.npc?
        npc_stats(participation)[:defense].to_i
      else
        participation.character&.defense.to_i
      end
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
        block_table: block["block_table"]
      }
    end

    def hit_result(attacker, defender, action_key, body_part)
      chance = BASE_HIT_CHANCE
      chance += stat(attacker, :dexterity) * 0.3
      chance += stat(attacker, :accuracy) * 0.5
      chance += Game::Combat::ActionCatalog.attack_hit_bonus(action_key)
      chance += BODY_PART_HIT_MODIFIERS.fetch(body_part, 0)
      chance -= stat(defender, :agility) * 0.2
      chance -= stat(defender, :evasion) * 0.4
      chance = chance.clamp(5.0, 95.0)

      roll = rng.rand(100)
      {hit: roll < chance, roll:, chance: chance.round(1)}
    end

    def dodge_result(attacker, defender, action_key, body_part)
      chance = BASE_DODGE_CHANCE
      chance += stat(defender, :agility) * 0.4
      chance += stat(defender, :evasion) * 0.3
      chance += stat(defender, :luck) * 0.1
      chance += BODY_PART_DODGE_MODIFIERS.fetch(body_part, 0)
      chance -= stat(attacker, :dexterity) * 0.15
      chance -= stat(attacker, :accuracy) * 0.25
      chance -= 10 if action_key == "aimed"
      chance = chance.clamp(0.0, 40.0)

      roll = rng.rand(100)
      {dodged: roll < chance, roll:, chance: chance.round(1)}
    end

    def critical_result(attacker, defender, action_key, body_part)
      chance = BASE_CRIT_CHANCE
      chance += stat(attacker, :luck) * 0.3
      chance += stat(attacker, :critical_chance)
      chance += 10 if action_key == "aimed"
      chance += 5 if body_part == "head"
      chance += 2 if body_part == "stomach"
      chance -= 3 if body_part == "legs"
      chance -= stat(defender, :luck) * 0.15
      chance = chance.clamp(1.0, 50.0)

      roll = rng.rand(100)
      {critical: roll < chance, roll:, chance: chance.round(1)}
    end

    def damage_amount(attacker, defender, action_key, body_part, critical:)
      attack = attack_power(attacker) + rng.rand(1..5)
      attack *= Game::Combat::ActionCatalog.attack_damage_multiplier(action_key)
      attack *= BODY_PART_DAMAGE_MULTIPLIERS.fetch(body_part, 1.0)

      damage = attack.round - (defense_power(defender) / DEFENSE_DIVISOR)
      damage = (damage * CRITICAL_MULTIPLIER).round if critical[:critical]
      [damage, MIN_DAMAGE].max
    end

    def block_covers?(block, body_part)
      return false if block.blank?

      Array(block["body_parts"]).map(&:to_s).include?(body_part)
    end

    def stat(participation, stat_name)
      if participation.npc?
        npc_stats(participation)[stat_name].to_i
      else
        character_stat(participation.character, stat_name)
      end
    end

    def character_stat(character, stat_name)
      return 0 unless character
      return character.critical_chance if stat_name == :critical_chance
      return character.agility if stat_name == :agility

      direct = character.public_send(stat_name) if character.respond_to?(stat_name)
      return direct.to_i if direct.present?

      character.stats.get(stat_name).to_i
    end

    def npc_stats(participation)
      npc = participation.npc_template
      config = Game::World::ArenaNpcConfig.find_npc(npc&.npc_key)
      stats = if config
        Game::World::ArenaNpcConfig.extract_stats(config)
      else
        level = npc&.level.to_i.positive? ? npc.level.to_i : 1
        {
          attack: npc&.metadata&.dig("base_damage") || npc&.metadata&.dig("damage") || (level * 3 + 5),
          defense: npc&.metadata&.dig("base_defense") || npc&.metadata&.dig("defense") || (level * 2 + 3),
          agility: npc&.metadata&.dig("agility") || level + 5,
          dexterity: npc&.metadata&.dig("dexterity") || level + 5,
          evasion: npc&.metadata&.dig("evasion") || level / 2,
          accuracy: npc&.metadata&.dig("accuracy") || level + 5,
          luck: npc&.metadata&.dig("luck") || 5 + (level / 5),
          critical_chance: npc&.metadata&.dig("crit_chance") || 10
        }
      end

      stats.with_indifferent_access
    end
  end
end
