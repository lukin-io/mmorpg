# frozen_string_literal: true

module Arena
  # Adapts a player or immutable NPC participation snapshot into the same
  # numeric formula inputs. No state changes; no item names infer stats.
  class CombatAttributes
    def self.for(participation)
      new(participation).to_h
    end

    def self.for_character(character)
      new(nil).player_attributes(character)
    end

    def initialize(participation)
      @participation = participation
    end

    def to_h
      participation.npc? ? npc_attributes : player_attributes
    end

    private

    attr_reader :participation

    def npc_attributes
      data = participation.npc_combat_data
      stats = data.fetch("stats", {})
      display = data.fetch("display_stats", {})
      family = Game::Combat::Calibration.config.fetch("npc_families").fetch(participation.npc_template.npc_key, {})
      values = {
        strength: display.fetch("strength", stats.fetch("strength", 0)),
        dexterity: display.fetch("dexterity", stats["dexterity"].to_i.nonzero? || stats.fetch("agility", 0)),
        luck: display.fetch("luck", stats.fetch("luck", 0)),
        armor: display.fetch("armor_class", stats.fetch("defense", 0)),
        accuracy: display.fetch("accuracy", stats.fetch("accuracy", 0)),
        evasion: display.fetch("evasion", stats.fetch("evasion", 0)),
        crushing: display.fetch("crushing", stats.fetch("crit_chance", 0)),
        fortitude: display.fetch("endurance", 0),
        penetration: display.fetch("armor_penetration", stats.fetch("armor_penetration", 0)),
        resistance: data.fetch("physical_resistance", 0),
        weapon_damage: family.fetch("weapon_damage", 0),
        damage_multiplier: family.fetch("damage_multiplier", 1.0),
        armor_multiplier: family.fetch("armor_multiplier", 1.0),
        knowledge: display.fetch("knowledge", 1)
      }
      values[:base_attack] = stats.fetch("attack", 0) unless values[:strength].positive?
      values
    end

    public

    def player_attributes(character = participation.character)
      return {} unless character

      stats = character.stats
      {
        strength: stats.get(:strength).to_i,
        dexterity: stats.get(:dexterity).to_i,
        luck: stats.get(:luck).to_i,
        knowledge: stats.get(:intelligence).to_i,
        armor: character.armor_class,
        weapon_damage: character.equipment_effect_value("attack", "attack_power") + character.equipped_weapon_damage,
        mastery: character.weapon_mastery,
        accuracy: character.accuracy_bonus,
        evasion: character.dodge_bonus,
        crushing: character.crushing_percent,
        fortitude: character.fortitude_percent,
        penetration: character.armor_pierce_percent,
        resistance: character.passive_skill_level(:physical_damage_resistance),
        fatigue: Characters::FatigueService.new(character:).current_percent,
        damage_multiplier: artifact_multiplier(character)
      }
    end

    private

    def artifact_multiplier(character)
      return 1.0 if participation&.arena_match&.metadata.to_h["fight_kind"] == "no_weapons"

      Game::Combat::Calibration.config.fetch("artifact_multipliers").fetch(character.metadata.to_h.fetch("artifact_grade", "none"), 1.0)
    end
  end
end
