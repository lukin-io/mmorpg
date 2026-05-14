# frozen_string_literal: true

module PlayerProfileHelper
  PROFILE_EQUIPMENT_SLOTS = [
    ["head", "Helmet"],
    ["amulet", "Necklace"],
    ["main_hand", "Weapon"],
    ["belt", "Belt"],
    ["belt_1", "Belt Item"],
    ["belt_2", "Belt Item"],
    ["belt_3", "Belt Item"],
    ["feet", "Boots"],
    ["pocket", "Pocket"],
    ["pocket_1", "Pocket Item"],
    ["bracers", "Bracers"],
    ["hands", "Gloves"],
    ["off_hand", "Weapon/Shield"],
    ["ring_1", "Ring"],
    ["ring_2", "Ring"],
    ["ring_3", "Ring"],
    ["ring_4", "Ring"],
    ["chest", "Armor"],
    ["legs", "Pants"],
    ["relic", "Relic"]
  ].freeze

  def profile_stat_rows(character)
    [
      ["Strength", stat_value(character, :strength)],
      ["Dexterity", stat_value(character, :dexterity)],
      ["Luck", stat_value(character, :luck)],
      ["Knowledge", stat_value(character, :intelligence)],
      ["Health", stat_value(character, :vitality)]
    ]
  end

  def profile_combat_rows(character)
    [
      ["Armor class", character.defense],
      ["Dodge", stat_value(character, :dexterity)],
      ["Accuracy", stat_value(character, :dexterity)],
      ["Crushing", character.attack_power],
      ["Fortitude", character.max_hp],
      ["Armor pierce", character.critical_chance]
    ]
  end

  def profile_location(character)
    position = character.position
    return "Unknown" unless position

    [position.zone&.name, "[#{position.x}, #{position.y}]"].compact.join(" ")
  end

  def profile_skill_level(character, key)
    character.passive_skill_level(key).to_s.rjust(3, "0")
  end

  def profile_attack_cost
    Game::Combat::ActionCatalog.attack_cost("simple")
  rescue NameError, KeyError, NoMethodError
    45
  end

  def profile_fatigue(character)
    character.resource_pools.to_h.fetch("fatigue", 0).to_i
  end

  private

  def stat_value(character, primary, fallback = nil)
    value = character.stats.get(primary).to_i
    return value if value.positive? || fallback.nil?

    character.stats.get(fallback).to_i
  end
end
