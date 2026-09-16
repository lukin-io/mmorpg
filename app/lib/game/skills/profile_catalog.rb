# frozen_string_literal: true

module Game
  module Skills
    # Read-only source table layout. Nil perk keys are visible references, never
    # allocation inputs or effect definitions; PerkRegistry owns selectable keys.
    # Profession keys only project saved counters, without creating growth rules.
    module ProfileCatalog
      SKILL_COLUMNS = [[:combat, :resistance, :magic], [:peace_world]].freeze
      PROFESSION_ROWS = {
        thievery: "Thievery", trading: "Trading", calligraphy: "Calligraphy",
        jewelry: "Jewelry", craftsmanship: "Craftsmanship", doctor: "Doctor",
        alchemy: "Alchemy", mining: "Mining", fishing: "Fishing", hunting: "Hunting",
        cooking: "Cooking", logging: "Logging", carpentry: "Carpentry",
        steelmaking: "Steelmaking", herbalism: "Herbalism"
      }.freeze
      PERK_COLUMNS = [[:profession, :auxiliary], [:stat, :resistance, :magic, :warrior]].freeze
      PERK_CATEGORIES = {
        profession: {name: "Professions", rows: [
          ["Mining", nil], ["Wood Processing", nil], ["Lumberjack", nil],
          ["Potion Making", nil], ["Pickpocket", nil], ["Merchant", :merchant],
          ["Cook", nil], ["Naturalist", nil], ["Gem Cutting", nil],
          ["Metal Smelting", nil], ["Butchery", nil], ["Fishing", nil],
          ["Skilled Hands", nil], ["Healer", :healer], ["Calligraphy", nil]
        ]},
        auxiliary: {name: "Auxiliary Perks", rows: [
          ["Careful Fighter", :careful_fighter], ["Nature Child", nil],
          ["Dungeon Child", nil], ["Life Extension", nil], ["Unarmed Combat", nil],
          ["Strong Back", nil]
        ]},
        stat: {name: "Stat Perks", rows: [
          ["More Strength", :more_strength], ["More Dexterity", nil],
          ["More Luck", nil], ["More Knowledge", nil], ["More Health", nil]
        ]},
        resistance: {name: "Resistances", rows: [
          ["Fire Magic Resistance", nil], ["Air Magic Resistance", nil],
          ["Water Magic Resistance", nil], ["Earth Magic Resistance", nil]
        ]},
        magic: {name: "Magic Perks", rows: [
          ["Fire Mage", nil], ["Air Mage", nil], ["Water Mage", nil], ["Earth Mage", nil]
        ]},
        warrior: {name: "Warrior Perks", rows: [
          ["Rogue", nil], ["Duelist", nil], ["Cutthroat", nil], ["Berserker", nil],
          ["Guardsman", nil], ["Knight", nil], ["Paladin", nil], ["Witcher", nil]
        ]}
      }.freeze
    end
  end
end
