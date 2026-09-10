# frozen_string_literal: true

admin = User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@browser-rpg.test")
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

  # Inventory-only reference definitions remain separate from the authored Shop.
  shop_items = [
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
    }
  ]

  starter_shop_goods = JSON.parse(File.read(Rails.root.join("db/seeds/data/starter_shop.json")))
  shop_items.concat(starter_shop_goods.map(&:symbolize_keys))

  license_items = [
    {key: "trading_license_i", name: "Trading License I", kind: "trading", price: 300, days: 3, stock: 9},
    {key: "trading_license_ii", name: "Trading License II", kind: "trading", price: 800, days: 10, stock: 666},
    {key: "trading_license_iii", name: "Trading License III", kind: "trading", price: 2_000, days: 30, stock: 4},
    {key: "doctor_license_i", name: "Doctor License I", kind: "doctor", price: 300, days: 5, stock: 10},
    {key: "doctor_license_ii", name: "Doctor License II", kind: "doctor", price: 550, days: 10, stock: 9},
    {key: "doctor_license_iii", name: "Doctor License III", kind: "doctor", price: 800, days: 15, stock: 10}
  ]
  license_items.each_with_index do |license, index|
    rules = {
      "kind" => license.fetch(:kind), "duration_days" => license.fetch(:days), "tier" => index % 3 + 1,
      "required_perk" => license.fetch(:kind) == "trading" ? "merchant" : "healer"
    }
    rules["required_unlock"] = "merchant" if license.fetch(:kind) == "trading"
    rules["required_unlock"] = "traumatologist" if license.fetch(:kind) == "doctor" && index > 3
    description = if license.fetch(:kind) == "trading"
      "Allows trading with other players. Requires the Merchant ability."
    elsif index == 3
      "Allows work as a doctor. Requires the Healer ability."
    else
      "Allows work as a doctor. Requires the Healer ability and completion of the Traumatologist quest."
    end
    shop_items << {
      key: license.fetch(:key), name: license.fetch(:name), item_type: "misc", slot: "none",
      weight: 1, stack_limit: 1, base_price: license.fetch(:price), durability_max: 1,
      requirements: {}, stat_modifiers: {},
      enhancement_rules: {
        "inventory_family" => "things", "subcategory" => "misc",
        "description" => description,
        "license" => rules,
        "shop" => {"sold" => true, "mode" => "licenses", "position" => index + 1},
        "shop_stock" => {"current" => license.fetch(:stock)}
      }
    }
  end

  shop_items.each do |attrs|
    item = ItemTemplate.find_or_initialize_by(key: attrs[:key])
    # Reload under lock before reading stock or correcting durability. A trade
    # or another seed may have committed since the initial template lookup.
    item.with_lock do
      # A source correction changes future goods, not the durability of items
      # already acquired. Share each owned row lock with durability writers.
      if item.persisted? && item.durability_max != attrs.fetch(:durability_max)
        InventoryItem.where(item_template: item).lock.find_each do |owned|
          properties = owned.properties.to_h
          maximum = properties["max_durability"].presence || item.durability_max
          current = properties["current_durability"].presence || properties["durability"].presence || maximum
          owned.update!(properties: properties.merge("max_durability" => maximum, "current_durability" => current))
        end
      end
      rules = attrs.fetch(:enhancement_rules, {}).deep_dup
      if item.persisted? && item.shop_stock_limited? && rules.key?("shop_stock")
        rules["shop_stock"] = item.shop_stock
      end
      item.assign_attributes(attrs.merge(enhancement_rules: rules))
      item.save!
    end
  end
  puts "Created/Updated #{shop_items.size} shop item templates"

  # Operators can refresh authored Shop content without granting player items.
  if main_character && ENV["SHOP_CATALOG_ONLY"] != "1"
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
      next if inventory.inventory_items.where("properties ->> 'seed_key' = ?", key).exists?

      item = inventory.inventory_items.build
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
