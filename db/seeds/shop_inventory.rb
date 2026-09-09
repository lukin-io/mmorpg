# frozen_string_literal: true

admin = User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@browser-rpg.test")
lukin_user = User.find_by(email: "second@lukin.io") || User.find_by(email: "lukin.maksim@gmail.com")
main_character = Character.find_by(user: admin, name: "max_kerby") if admin

if defined?(ItemTemplate)
  # Source-backed NPC material item templates.
  material_items = [
    {key: "wood_chips", name: "Wood Chips", item_type: "material", weight: 1},
    {key: "rat_tail", name: "Rat Tail", item_type: "material", weight: 1}
  ]

  material_items.each do |attrs|
    ItemTemplate.find_or_create_by!(key: attrs[:key]) do |item|
      item.name = attrs[:name]
      item.item_type = attrs[:item_type]
      item.slot = "material"
      item.weight = attrs[:weight]
      item.stack_limit = 99
      item.stat_modifiers = {}
    end
  end
  puts "Created #{material_items.size} material item templates"

  shop_items = [
    {
      key: "practice_knife",
      name: "Practice Knife",
      item_type: "equipment",
      slot: "main_hand",
      weight: 3,
      stack_limit: 1,
      base_price: 35,
      durability_max: 20,
      requirements: {"level" => 1, "ap" => 45},
      stat_modifiers: {"attack" => 2, "damage_min" => 1, "damage_max" => 2, "armor_pierce" => 1, "weapon_family" => "knife"},
      enhancement_rules: {"subcategory" => "knives", "shop_stock" => {"current" => 464, "max" => 500}}
    },
    {
      key: "militia_sword",
      name: "Militia Sword",
      item_type: "equipment",
      slot: "main_hand",
      weight: 7,
      stack_limit: 1,
      base_price: 160,
      durability_max: 34,
      requirements: {"level" => 3, "strength" => 2, "ap" => 48},
      stat_modifiers: {"attack" => 5, "weapon_family" => "sword"},
      enhancement_rules: {"subcategory" => "swords", "shop_stock" => {"current" => 500, "max" => 500}}
    },
    {
      key: "padded_jacket",
      name: "Padded Jacket",
      item_type: "equipment",
      slot: "chest",
      weight: 5,
      stack_limit: 1,
      base_price: 95,
      durability_max: 28,
      requirements: {"level" => 1, "strength" => 1},
      stat_modifiers: {"defense" => 3, "knowledge" => 1},
      enhancement_rules: {"subcategory" => "armor", "shop_stock" => {"current" => 74, "max" => 500}}
    },
    {
      key: "minor_healing_elixir",
      name: "Minor Healing Elixir",
      item_type: "consumable",
      slot: "none",
      weight: 1,
      stack_limit: 20,
      base_price: 24,
      durability_max: 0,
      requirements: {"level" => 1},
      stat_modifiers: {"heal_hp" => 35},
      enhancement_rules: {"inventory_family" => "elixirs", "shop_stock" => {"current" => 500, "max" => 500}}
    },
    {
      key: "license_market_stall",
      name: "Trader License",
      item_type: "misc",
      slot: "none",
      weight: 1,
      stack_limit: 1,
      base_price: 500,
      durability_max: 0,
      requirements: {"level" => 5},
      stat_modifiers: {}
    },
    {
      key: "knowledge_ring",
      name: "Knowledge Ring",
      item_type: "equipment",
      slot: "ring",
      weight: 1,
      stack_limit: 1,
      base_price: 18,
      durability_max: 30,
      requirements: {"level" => 5},
      stat_modifiers: {"knowledge" => 3},
      enhancement_rules: {"subcategory" => "jewelry", "source_name" => "Кольцо Знаний", "shop_stock" => {"current" => 460, "max" => 500}}
    },
    {
      key: "dexterity_ring",
      name: "Dexterity Ring",
      item_type: "equipment",
      slot: "ring",
      weight: 1,
      stack_limit: 1,
      base_price: 18,
      durability_max: 30,
      requirements: {"level" => 5, "health" => 7},
      stat_modifiers: {"dexterity" => 3},
      enhancement_rules: {"subcategory" => "jewelry", "source_name" => "Кольцо Ловкости", "shop_stock" => {"current" => 36, "max" => 500}}
    },
    {
      key: "subtlety_ring",
      name: "Subtlety Ring",
      item_type: "equipment",
      slot: "ring",
      weight: 1,
      stack_limit: 1,
      base_price: 10,
      durability_max: 30,
      requirements: {"level" => 3, "dexterity" => 9},
      stat_modifiers: {"crushing" => -5, "evasion" => 5, "accuracy" => 5},
      enhancement_rules: {"subcategory" => "jewelry", "source_name" => "Кольцо Тонкости", "shop_stock" => {"current" => 477, "max" => 500}}
    },
    {
      key: "soul_hunter_pendant",
      name: "Soul Hunter Pendant",
      item_type: "equipment",
      slot: "amulet",
      weight: 2,
      stack_limit: 1,
      base_price: 30,
      durability_max: 30,
      requirements: {"level" => 5, "knowledge" => 15},
      stat_modifiers: {"hp" => 5, "mana" => 20, "strength" => -1, "knowledge" => 1},
      enhancement_rules: {"subcategory" => "jewelry", "source_name" => "Кулон Ловца Душ", "shop_stock" => {"current" => 498, "max" => 500}}
    },
    {
      key: "emerald_sash",
      name: "Emerald Sash",
      item_type: "equipment",
      slot: "belt",
      weight: 4,
      stack_limit: 1,
      base_price: 100,
      durability_max: 30,
      requirements: {"level" => 5, "knowledge" => 8, "health" => 7},
      stat_modifiers: {"fortitude" => 20, "armor_class" => 2, "hp" => 40, "mana" => 20, "knowledge" => 1, "skill_bonuses" => {"knife_mastery" => 5, "staff_mastery" => 5}, "earth_resistance" => 7},
      enhancement_rules: {"subcategory" => "belts", "properties" => {"pockets" => 2}, "source_name" => "Изумрудный Кушак"}
    },
    {
      key: "student_boots",
      name: "Apprentice Boots",
      item_type: "equipment",
      slot: "feet",
      weight: 8,
      stack_limit: 1,
      base_price: 200,
      durability_max: 20,
      requirements: {"level" => 5, "luck" => 12, "knowledge" => 13},
      stat_modifiers: {"crushing" => 10, "fortitude" => 10, "armor_class" => 3, "mana" => 20, "luck" => 2, "knowledge" => 2, "skill_bonuses" => {"staff_mastery" => 5}, "all_resistances" => 8},
      enhancement_rules: {"subcategory" => "boots", "source_name" => "Сапожки Ученика"}
    },
    {
      key: "cowardly_gloves",
      name: "Cowardly Gloves",
      item_type: "equipment",
      slot: "hands",
      weight: 6,
      stack_limit: 1,
      base_price: 75,
      durability_max: 30,
      requirements: {"level" => 5, "dexterity" => 16},
      stat_modifiers: {"evasion" => 10, "armor_class" => 1, "strength" => -1, "dexterity" => 2, "knife_skill" => 5},
      enhancement_rules: {"subcategory" => "gloves", "source_name" => "Трусливые Перчатки"}
    },
    {
      key: "mage_dagger",
      name: "Mage Dagger",
      item_type: "equipment",
      slot: "main_hand",
      weight: 5,
      stack_limit: 1,
      base_price: 75,
      durability_max: 50,
      requirements: {"level" => 5, "ap" => 55, "luck" => 5, "knowledge" => 15, "knife_skill" => 10},
      stat_modifiers: {"damage_min" => 4, "damage_max" => 9, "crushing" => 25, "fortitude" => 5, "armor_pierce" => 10, "hp" => 15, "mana" => 15, "luck" => 2, "weapon_family" => "knife"},
      enhancement_rules: {"subcategory" => "knives", "source_name" => "Кинжал Мага"}
    },
    {
      key: "hunter_knife",
      name: "Hunter Knife",
      item_type: "equipment",
      slot: "main_hand",
      weight: 6,
      stack_limit: 1,
      base_price: 19,
      durability_max: 30,
      requirements: {"level" => 3, "dexterity" => 16, "ap" => 26, "knife_skill" => 10, "dual_wield_skill" => 10},
      stat_modifiers: {"damage_min" => 4, "damage_max" => 6, "evasion" => 10, "armor_pierce" => 5, "dexterity" => 1, "knife_skill" => 5, "weapon_family" => "knife"},
      enhancement_rules: {"subcategory" => "knives", "source_name" => "Нож Охотника", "shop_stock" => {"current" => 460, "max" => 500}}
    },
    {
      key: "small_crescent_staff",
      name: "Small Crescent Staff",
      item_type: "equipment",
      slot: "main_hand",
      weight: 11,
      stack_limit: 1,
      base_price: 150,
      durability_max: 30,
      requirements: {"level" => 6, "luck" => 6, "dexterity" => 10, "knowledge" => 15, "ap" => 63, "staff_skill" => 20},
      stat_modifiers: {"damage_min" => 6, "damage_max" => 11, "evasion" => 15, "accuracy" => 10, "armor_pierce" => 14, "mana" => 30, "dexterity" => 1, "knowledge" => 2, "weapon_family" => "staff"},
      enhancement_rules: {"subcategory" => "staves", "source_name" => "Малый Жезл Полумесяца", "shop_stock" => {"current" => 490, "max" => 500}}
    },
    {
      key: "north_wind_bracers",
      name: "North Wind Bracers",
      item_type: "equipment",
      slot: "bracers",
      weight: 8,
      stack_limit: 1,
      base_price: 60,
      durability_max: 40,
      requirements: {"level" => 5, "knowledge" => 17},
      stat_modifiers: {"accuracy" => 10, "armor_class" => 2, "hp" => 10, "mana" => 10, "knowledge" => 1},
      enhancement_rules: {"subcategory" => "bracers", "source_name" => "Наручи Северного Ветра"}
    },
    {
      key: "damage_armor",
      name: "Damage Armor",
      item_type: "equipment",
      slot: "chest",
      weight: 11,
      stack_limit: 1,
      base_price: 60,
      durability_max: 45,
      requirements: {"level" => 4, "luck" => 15, "health" => 7},
      stat_modifiers: {"crushing" => 20, "armor_class" => 6, "hp" => 7, "luck" => 1},
      enhancement_rules: {"subcategory" => "armor", "properties" => {"layering" => "Can be worn over chainmail"}, "source_name" => "Доспех Повреждений"}
    },
    {
      key: "knowledge_shirt",
      name: "Knowledge Shirt",
      item_type: "equipment",
      slot: "chest",
      weight: 1,
      stack_limit: 1,
      base_price: 10,
      durability_max: 20,
      requirements: {"level" => 2},
      stat_modifiers: {"knowledge" => 1},
      enhancement_rules: {"subcategory" => "armor", "source_name" => "Рубашка Знаний", "shop_stock" => {"current" => 74, "max" => 500}}
    },
    {
      key: "starwatcher_cap",
      name: "Starwatcher Cap",
      item_type: "equipment",
      slot: "head",
      weight: 2,
      stack_limit: 1,
      base_price: 90,
      durability_max: 40,
      requirements: {"level" => 5, "knowledge" => 10},
      stat_modifiers: {"armor_class" => 1, "hp" => 10, "mana" => 30, "knowledge" => 3, "fire_resistance" => 5, "water_resistance" => 5, "air_resistance" => 5, "earth_resistance" => 5},
      enhancement_rules: {"subcategory" => "helmets", "source_name" => "Колпак Звездочёта"}
    },
    {
      key: "reset_scroll",
      name: "Reset Scroll",
      item_type: "consumable",
      slot: "none",
      weight: 1,
      stack_limit: 1,
      base_price: 1000,
      durability_max: 1,
      requirements: {"level" => 5, "health" => 10},
      stat_modifiers: {"reset_allocation" => true},
      enhancement_rules: {"inventory_family" => "things", "subcategory" => "scrolls", "description" => "Resets parameters, skills, and perks for redistribution.", "source_name" => "Свиток Обнуления"}
    },
    {
      key: "imp_helper_summon",
      name: "Imp Helper Summon",
      item_type: "consumable",
      slot: "none",
      weight: 1,
      stack_limit: 1,
      base_price: 1000,
      durability_max: 1,
      requirements: {"level" => 8, "linguistics" => 60},
      stat_modifiers: {"production_speed_percent" => 10},
      enhancement_rules: {"inventory_family" => "things", "subcategory" => "scrolls", "description" => "Summons a helper for production speed. Requirements intentionally block low-level use.", "source_name" => "Призыв импа-помощника"}
    },
    {
      key: "duel_permit_i",
      name: "Duel Permit I",
      item_type: "consumable",
      slot: "none",
      weight: 1,
      stack_limit: 10,
      base_price: 16,
      durability_max: 1,
      requirements: {"level" => 5, "stealth" => 20},
      stat_modifiers: {},
      enhancement_rules: {"inventory_family" => "things", "subcategory" => "scrolls", "description" => "Starts a low-trauma open fight.", "source_name" => "Разрешение на поединок I", "shop_stock" => {"current" => 459, "max" => 500}}
    }
  ]

  shop_items.each do |attrs|
    item = ItemTemplate.find_or_initialize_by(key: attrs[:key])
    item.assign_attributes(attrs)
    item.save!
  end
  puts "Created/Updated #{shop_items.size} shop item templates"

  if main_character
    starter_items = {
      "knowledge_ring" => {"current_durability" => 30},
      "dexterity_ring" => {"current_durability" => 29},
      "emerald_sash" => {"current_durability" => 29},
      "student_boots" => {"current_durability" => 20},
      "cowardly_gloves" => {"current_durability" => 30},
      "mage_dagger" => {"current_durability" => 49},
      "north_wind_bracers" => {"current_durability" => 39},
      "soul_hunter_pendant" => {"current_durability" => 30},
      "damage_armor" => {"current_durability" => 45},
      "starwatcher_cap" => {"current_durability" => 40},
      "reset_scroll" => {"current_durability" => 1, "expires_at" => "2026-11-18 12:22"},
      "imp_helper_summon" => {"current_durability" => 1}
    }

    inventory = main_character.inventory || main_character.create_inventory!(slot_capacity: 48, weight_capacity: 160)
    starter_items.each do |key, properties|
      template = ItemTemplate.find_by!(key:)
      item = inventory.inventory_items.where("properties ->> 'seed_key' = ?", key).first ||
        inventory.inventory_items.build(item_template: template, weight: template.weight, quantity: 1)
      item.assign_attributes(
        item_template: template,
        weight: template.weight,
        quantity: 1,
        properties: properties.merge("seed_key" => key)
      )
      item.save!
    end
    inventory.update!(current_weight: inventory.inventory_items.sum("weight * quantity"))
  end
end
