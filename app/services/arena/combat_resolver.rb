# frozen_string_literal: true

require "yaml"

module Arena
  # Resolves one arena attack.
  #
  # Hit/block coefficients still load from config/gameplay/combat_resolution.yml.
  # Soft-release Ashen damage core (base_hit / crit / evasion / defense) is
  # authored in this class — see dodge_result, critical_result, damage_amount.
  class CombatResolver
    TABLE_PATH = Rails.root.join("config/gameplay/combat_resolution.yml")
    # Soft-release crit multiplier on resolved base_hit (before armor).
    CRITICAL_MULTIPLIER = 2.0
    BASE_HIT_MIN_FACTOR = 0.6
    BASE_HIT_MAX_FACTOR = 1.3
    CRIT_LUCK_FACTOR = 1.8
    CRIT_DEXTERITY_FACTOR = 0.3
    CRIT_CHANCE_MIN = 5.0
    CRIT_CHANCE_MAX = 75.0
    EVASION_FACTOR = 1.5
    EVASION_ACCURACY_FACTOR = 0.4
    EVASION_CHANCE_MIN = 5.0
    EVASION_CHANCE_MAX = 70.0

    attr_reader :match, :rng

    def initialize(match:, rng: Random.new)
      @match = match
      @rng = rng
      @table = self.class.resolution_table
    end

    def self.resolution_table
      @resolution_table ||= YAML.load_file(TABLE_PATH).with_indifferent_access
    end

    def self.reload_table!
      @resolution_table = nil
      resolution_table
    end

    def resolve_physical_attack(attacker_participation:, defender_participation:, action_key:, body_part:, block: nil)
      action_key = action_key.to_s
      body_part = body_part.to_s

      hit = hit_result(attacker_participation, defender_participation, action_key, body_part)
      return outcome(:miss, action_key:, body_part:, hit:) unless hit[:hit]

      dodge = dodge_result(attacker_participation, defender_participation, action_key, body_part)
      return outcome(:dodge, action_key:, body_part:, hit:, dodge:) if dodge[:dodged]

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
      if participation.npc?
        npc_stats(participation)[:attack].to_i
      else
        participation.character&.attack_power.to_i
      end
    end

    def magic_attack_power(participation)
      if participation.npc?
        stats = npc_stats(participation)
        magic = stats[:magic_power].presence || stats[:magic].presence
        # Mage archetype falls back to attack only when magic_power unset.
        magic.to_i.positive? ? magic.to_i : stats[:attack].to_i
      else
        participation.character&.magic_power.to_i
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

    attr_reader :table

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
      cfg = table.fetch(:hit_chance)
      chance = table.fetch(:base_hit_chance).to_f
      chance += stat(attacker, :dexterity) * cfg.fetch(:dexterity).to_f
      chance += stat(attacker, :accuracy) * cfg.fetch(:accuracy).to_f
      chance += Game::Combat::ActionCatalog.attack_hit_bonus(action_key)
      chance += body_mod(:body_part_hit_modifiers, body_part)
      chance -= stat(defender, :agility) * cfg.fetch(:defender_agility).to_f
      chance -= stat(defender, :evasion) * cfg.fetch(:defender_evasion).to_f
      chance = chance.clamp(cfg.fetch(:min).to_f, cfg.fetch(:max).to_f)

      roll = rng.rand(100)
      {hit: roll < chance, roll:, chance: chance.round(1)}
    end

    def dodge_result(attacker, defender, _action_key, _body_part)
      # evasion_chance = (evasion * 1.5) - (accuracy * 0.4), clamped 5..70
      chance = (
        (stat(defender, :evasion) * EVASION_FACTOR) -
        (stat(attacker, :accuracy) * EVASION_ACCURACY_FACTOR)
      ).clamp(EVASION_CHANCE_MIN, EVASION_CHANCE_MAX)

      roll = rng.rand(100)
      {dodged: roll < chance, roll:, chance: chance.round(1)}
    end

    def critical_result(attacker, _defender, _action_key, _body_part)
      # crit_chance = (luck * 1.8) + (dexterity * 0.3), clamped 5..75
      # Do not add Character#critical_chance (UI composite) — luck/dex only.
      chance = (
        (stat(attacker, :luck) * CRIT_LUCK_FACTOR) +
        (stat(attacker, :dexterity) * CRIT_DEXTERITY_FACTOR)
      ).clamp(CRIT_CHANCE_MIN, CRIT_CHANCE_MAX)

      roll = rng.rand(100)
      {critical: roll < chance, roll:, chance: chance.round(1)}
    end

    def block_result(attacker, defender, block, body_part)
      cfg = table.fetch(:block_chance)
      covered_parts = Array(block["body_parts"]).map(&:to_s)
      chance = table.fetch(:base_block_chance).to_f
      chance += defense_power(defender) * cfg.fetch(:defense).to_f
      chance += stat(defender, :agility) * cfg.fetch(:agility).to_f
      chance += stat(defender, :dexterity) * cfg.fetch(:dexterity).to_f
      chance += body_mod(:body_part_block_modifiers, body_part)
      chance -= stat(attacker, :accuracy) * cfg.fetch(:attacker_accuracy).to_f
      chance -= stat(attacker, :dexterity) * cfg.fetch(:attacker_dexterity).to_f
      chance -= [covered_parts.size - 1, 0].max * cfg.fetch(:extra_part_penalty).to_f
      chance = chance.clamp(cfg.fetch(:min).to_f, cfg.fetch(:max).to_f)

      roll = rng.rand(100)
      {blocked: roll < chance, roll:, chance: chance.round(1)}
    end

    def damage_amount(attacker, defender, action_key, body_part, critical:)
      magical = magical_attack?(action_key)
      power = (magical ? magic_attack_power(attacker) : attack_power(attacker)).to_f
      power = 1.0 if power <= 0

      # base_hit = random in [attack_power * 0.6, attack_power * 1.3]
      min_damage = power * BASE_HIT_MIN_FACTOR
      max_damage = power * BASE_HIT_MAX_FACTOR
      base_hit = min_damage + (rng.rand * (max_damage - min_damage))

      base_hit *= Game::Combat::ActionCatalog.attack_damage_multiplier(action_key)
      base_hit *= Game::Combat::ActionCatalog.body_part_multiplier(body_part)
      unless attacker.npc? || magical
        character = attacker.character
        family = character&.send(:equipment_weapon_family) if character
        base_hit *= Game::Skills::UseTrainer.weapon_damage_multiplier(character, family) if character
      end

      final_damage = critical[:critical] ? (base_hit * CRITICAL_MULTIPLIER) : base_hit

      # Armor absorption: max(final_damage - defense, 1)
      defense = defense_power(defender).to_f
      unless attacker.npc? || magical
        pierce = attacker.character&.armor_pierce_percent.to_f / 100.0
        defense *= (1.0 - pierce.clamp(0.0, 0.75))
      end
      if magical
        defense *= table.fetch(:magic_defense_factor, 0.65).to_f
      end

      damage = [final_damage - defense, table.fetch(:min_damage).to_i].max
      damage = apply_elemental_resistance(damage, attacker, defender, action_key)
      damage = apply_undergear_modifier(damage, attacker, defender)
      [damage.round, table.fetch(:min_damage).to_i].max
    end

    # Mist/Legend early pattern: wilderness without chest armor is punished.
    # Naked (or blade-only) players deal less and take more vs NPCs.
    def apply_undergear_modifier(damage, attacker, defender)
      if attacker.npc? && undergeared_player?(defender)
        return (damage * table.fetch(:undergear_incoming_multiplier, 1.45).to_f).round
      end
      if !attacker.npc? && undergeared_player?(attacker) && defender.npc?
        return (damage * table.fetch(:undergear_outgoing_multiplier, 0.82).to_f).round
      end

      damage
    end

    def undergeared_player?(participation)
      return false if participation.blank? || participation.npc?

      character = participation.character
      return true unless character&.inventory

      InventoryItem.where(inventory_id: character.inventory.id, equipped: true, equipment_slot: "chest").exists? == false
    end

    def magical_attack?(action_key)
      cfg = Game::Combat::ActionCatalog.attack_config(action_key)
      cfg["element"].to_s.present? || cfg.fetch("mana_cost", 0).to_i.positive?
    end

    def apply_elemental_resistance(damage, attacker, defender, action_key)
      element = Game::Combat::ActionCatalog.attack_config(action_key)["element"].to_s
      return damage if element.blank?

      resist = if defender.npc?
        raw = npc_stats(defender)[:resist].to_f
        # NPC resist stored as whole percent (0..100) or fraction; normalize.
        raw > 1.0 ? raw / 100.0 : raw
      else
        defender.character&.elemental_resistance_percent(element).to_f / 100.0
      end
      factor = (1.0 - resist.clamp(0.0, 0.5))
      (damage * factor).round
    end

    def block_covers?(block, body_part)
      return false if block.blank?

      Array(block["body_parts"]).map(&:to_s).include?(body_part)
    end

    def body_mod(section, body_part)
      table.fetch(section).fetch(body_part, 0).to_f
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

      case stat_name.to_sym
      when :critical_chance
        character.critical_chance.to_i
      when :agility
        character.agility.to_i
      when :accuracy
        character.accuracy_bonus.to_i
      when :evasion
        character.dodge_bonus.to_i
      when :attack, :attack_power
        character.attack_power.to_i
      when :defense, :armor_class
        character.defense.to_i
      else
        if character.respond_to?(stat_name)
          character.public_send(stat_name).to_i
        else
          character.stats.get(stat_name).to_i
        end
      end
    end

    def npc_stats(participation)
      override = participation.metadata.to_h["combat_stats"]
      if override.is_a?(Hash) && override.present?
        return override.with_indifferent_access
      end

      npc = participation.npc_template
      config = Game::World::ArenaNpcConfig.find_npc(npc&.npc_key)
      stats = if config
        Game::World::ArenaNpcConfig.extract_stats(config)
      else
        npc&.combat_stats || {}
      end

      stats.with_indifferent_access
    end
  end
end
