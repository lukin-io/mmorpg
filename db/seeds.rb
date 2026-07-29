lukin_user = nil
seed_admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "Password123!")

if defined?(User)
  admin = User.find_or_create_by!(email: "first@lukin.io") do |user|
    user.password = seed_admin_password
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)

  lukin_user = User.find_or_create_by!(email: "second@lukin.io") do |user|
    user.password = seed_admin_password
    user.confirmed_at = Time.current
  end
  lukin_user.add_role(:admin)
end

if defined?(Role)
  %i[player moderator gm admin].each do |role_name|
    Role.find_or_create_by!(name: role_name)
  end
end

if defined?(ChatChannel)
  ChatChannel.find_or_create_by!(slug: "global") do |channel|
    channel.name = "Global"
    channel.channel_type = :global
    channel.system_owned = true
  end
end

def zone_metadata_for(name)
  city_node = Game::World::CityCatalog::NODES.values.find { |node| node["zone_name"] == name }
  if city_node
    city_node_key = Game::World::CityCatalog::NODES.key(city_node)
    return {
      "city_key" => Game::World::CityCatalog::CITY_KEY,
      "city_node_key" => city_node_key,
      "title" => city_node["title"],
      "description" => "Forpost — #{city_node['title']}"
    }
  end

  case name
  when "Outpost Surroundings"
    {
      "source_map" => "m_1001_999"
    }
  else
    {}
  end
end

if defined?(Zone)
  city_zones = Game::World::CityCatalog::NODES.values.map do |node|
    {name: node["zone_name"], location_type: "city", width: 10, height: 10}
  end
  zones = city_zones + [
    {name: "Outpost Surroundings", location_type: "outdoor", width: 1000, height: 1000}
  ]

  zones.each do |attrs|
    zone = Zone.find_or_initialize_by(name: attrs[:name])
    zone.location_type = attrs[:location_type]
    zone.width = attrs[:width]
    zone.height = attrs[:height]
    zone.metadata = zone_metadata_for(attrs[:name])
    zone.save!
  end
end

forpost_city_zones = if defined?(Zone)
  Zone.where(location_type: "city").select do |zone|
    zone.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY
  end
else
  []
end

retire_world_action_targets = if defined?(WorldActionOffer)
  lambda do |target_type, targets|
    target_offers = WorldActionOffer.where(target_type:, target_id: targets.select(:id))
    live_statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
    target_offers.where(status: live_statuses).update_all(
      status: WorldActionOffer.statuses.fetch("cancelled"),
      error_message: "Authored world content was updated.",
      updated_at: Time.current
    )
    target_offers.update_all(target_type: nil, target_id: nil, updated_at: Time.current)
  end
end

if defined?(SpawnPoint) && defined?(Zone)
  city_zone_names = Game::World::CityCatalog::NODES.values.pluck("zone_name")
  central_square = Zone.find_by(
    name: Game::World::CityCatalog.node(Game::World::CityCatalog::STARTER_NODE_KEY)["zone_name"]
  )

  seeded_world_zones = Zone.where(name: city_zone_names + ["Outpost Surroundings"])
  SpawnPoint.where(zone: seeded_world_zones.or(Zone.where(id: forpost_city_zones.map(&:id)))).delete_all
  if central_square
    spawn = SpawnPoint.find_or_initialize_by(zone: central_square, x: 0, y: 0)
    spawn.assign_attributes(city_key: "forpost", default_entry: true)
    spawn.save!
  end
end

if defined?(MapTileTemplate)
  # Neverlands cities are node graphs, not grid maps. Remove obsolete city
  # tiles instead of retaining a parallel generic-town representation.
  city_zone_names = forpost_city_zones.map(&:name)
  MapTileTemplate.where(zone: city_zone_names).delete_all

  # Outpost Surroundings uses sparse authored overrides inside one logical
  # 1000x1000 region. Missing in-bounds rows use the deterministic passable
  # outdoor default shared by rendering and movement validation. cell_art stores
  # only a stable catalog key and zero-based sheet location; passability,
  # entrances, local actions, and hidden NPCs remain independent layers.
  outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
  outdoor_tiles = []
  if outpost_surroundings
    outdoor_zone_name = outpost_surroundings.name  # Store zone name as string, not the Zone object
    Game::World::CityCatalog::GATES.each_value do |gate|
      local_x, local_y = gate["local_coordinates"]
      outdoor_tiles << {
        zone: outdoor_zone_name,
        x: local_x,
        y: local_y,
        terrain_type: "outdoor",
        passable: true,
        metadata: {
          "city_gate" => gate["name"],
          "source_map" => gate["source_map"],
          "source_coordinates" => gate["source_coordinates"],
          "cell_art" => {
            "key" => "forpost_terrain",
            "column" => local_x.modulo(10),
            "row" => local_y.modulo(10)
          }
        }
      }
    end
    outdoor_tiles << {
      zone: outdoor_zone_name,
      x: 7,
      y: 7,
      terrain_type: "outdoor",
      passable: true,
      metadata: {
        "source_map" => "m_1001_999",
        "source_coordinates" => [1001, 999],
        "cell_art" => {
          "key" => "forpost_terrain",
          "column" => 7,
          "row" => 7
        },
        "local_actions" => [
          {
            "type" => "resource_search",
            "source_id" => "look",
            "label" => "Look Around",
            "description" => "Search this cell for herbs or local resources."
          }
        ]
      }
    }
    outdoor_tiles << {
      zone: outdoor_zone_name,
      x: 4,
      y: 6,
      terrain_type: "outdoor",
      passable: true,
      metadata: {
        "source_map" => "m_998_998",
        "source_coordinates" => [998, 998],
        "cell_art" => {
          "key" => "forpost_terrain",
          "column" => 4,
          "row" => 6
        }
      }
    }
  end

  outdoor_tiles.each do |attrs|
    next unless attrs[:zone]
    tile = MapTileTemplate.find_or_initialize_by(zone: attrs[:zone], x: attrs[:x], y: attrs[:y])
    tile.terrain_type = attrs[:terrain_type]
    tile.passable = attrs.fetch(:passable, true)
    tile.metadata = attrs.fetch(:metadata, {})
    tile.save!
  end

  if outpost_surroundings
    current_gate_cells = Game::World::CityCatalog::GATES.values.map { |gate| gate["local_coordinates"] }
    MapTileTemplate.where(zone: outpost_surroundings.name).find_each do |authored_tile|
      next unless authored_tile.metadata.to_h["city_gate"].present?
      next if current_gate_cells.include?([authored_tile.x, authored_tile.y])

      authored_tile.destroy!
    end
  end
end

# ------------------------------------------------------------------
# Gameplay feature sandboxes used by flow + feature documentation
# ------------------------------------------------------------------
# Use the users created at the top of the file (first@lukin.io, second@lukin.io)
# Fall back to alternative emails if those don't exist
admin ||= User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@browser-rpg.test")
lukin_user ||= User.find_by(email: "second@lukin.io") || User.find_by(email: "lukin.maksim@gmail.com")

main_character = nil
secondary_character = nil
lukin_character = nil

if defined?(Character) && admin
  main_character = Character.find_or_create_by!(user: admin, name: "max_kerby") do |char|
    char.level = 22
    char.experience = 125_000
    char.alignment = "light"
    char.allocated_stats = {"strength" => 16, "vitality" => 12, "dexterity" => 5}
    char.fatigue_percent = 0
    char.metadata = {}
  end
  main_character.reload
  main_character.inventory || main_character.create_inventory!(slot_capacity: 48, weight_capacity: 160)

  secondary_character = Character.find_or_create_by!(user: admin, name: "max_kerby_balance") do |char|
    char.level = 18
    char.experience = 82_000
    char.alignment = "balance"
    char.allocated_stats = {"intelligence" => 18, "vitality" => 6, "dexterity" => 4}
    char.fatigue_percent = 0
    char.metadata = {}
  end
  secondary_character.reload
  secondary_character.inventory || secondary_character.create_inventory!(slot_capacity: 42, weight_capacity: 130)

  if lukin_user
    lukin_character = Character.find_or_create_by!(user: lukin_user, name: "max_kerby_dark") do |char|
      char.level = 16
      char.experience = 61_000
      char.alignment = "dark"
      char.allocated_stats = {"dexterity" => 14, "strength" => 7, "vitality" => 5}
      char.fatigue_percent = 0
      char.metadata = {}
    end
    lukin_character.reload
    lukin_character.inventory || lukin_character.create_inventory!(slot_capacity: 36, weight_capacity: 140)
  end
end

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

if defined?(CurrencyWallet)
  if admin
    wallet = admin.currency_wallet || CurrencyWallet.create!(user: admin)
    wallet.adjust!(amount: 7_500, reason: "seed.initial_nv", metadata: {"source" => "starter_content"})
  end

  if lukin_user
    wallet = lukin_user.currency_wallet || CurrencyWallet.create!(user: lukin_user)
    wallet.adjust!(amount: 4_200, reason: "seed.initial_nv")
  end
end

# ==============================================================================
# Arena Rooms
# ==============================================================================
puts "Seeding Arena Rooms..."

if defined?(ArenaRoom)
  arena_rooms = [
    {
      name: "Training Hall",
      slug: "training",
      room_type: :training,
      level_min: 0,
      level_max: 10,
      alignment_restriction: nil,
      description: "Source-backed starter arena room for training fights."
    }
  ]

  arena_rooms.each do |room_data|
    ArenaRoom.find_or_create_by!(slug: room_data[:slug]) do |room|
      room.name = room_data[:name]
      room.room_type = room_data[:room_type]
      room.level_min = room_data[:level_min]
      room.level_max = room_data[:level_max]
      room.alignment_restriction = room_data[:alignment_restriction]
      room.active = true
      room.metadata = {description: room_data[:description]}
    end
    puts "  Created/Found ArenaRoom: #{room_data[:name]}"
  end
end

puts "Arena rooms seeding complete!"

# ==============================================================================
# Tile Buildings (Enterable structures on map tiles)
# ==============================================================================
puts "Seeding Tile Buildings..."

if defined?(TileBuilding) && defined?(Zone)
  outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
  tile_buildings = []

  if outpost_surroundings
    Game::World::CityCatalog::GATES.each do |gate_key, gate|
      node = Game::World::CityCatalog.node(gate["node_key"])
      destination_zone = Zone.find_by(name: node["zone_name"])
      next unless destination_zone

      local_x, local_y = gate["local_coordinates"]
      tile_buildings << {
        zone: outpost_surroundings.name,
        x: local_x,
        y: local_y,
        building_key: (gate_key == "west" ? "outpost_gate" : "outpost_#{gate_key}_gate"),
        building_type: "city",
        name: gate["name"],
        destination_zone:,
        destination_x: 0,
        destination_y: 0,
        icon: nil,
        required_level: 1,
        metadata: {
          "description" => "Enter Forpost through the #{gate['name']}.",
          "source_map" => gate["source_map"],
          "source_coordinates" => gate["source_coordinates"],
          "source_gate" => gate_key,
          "city_node_key" => gate["node_key"]
        }
      }
    end

    tile_buildings << {
      zone: outpost_surroundings.name,
      x: 4,
      y: 6,
      building_key: "frontier_village_entrance",
      building_type: "location",
      name: "Frontier Village",
      destination_zone: nil,
      destination_x: nil,
      destination_y: nil,
      icon: nil,
      required_level: 1,
      metadata: {
        "description" => "Enter the village from this world cell.",
        "source_map" => "m_998_998",
        "source_coordinates" => [998, 998],
        "landmark_kind" => "village",
        "location" => {
          "short_label" => "Village",
          "kind" => "village",
          "scene" => {"width" => 760, "height" => 255},
          "features" => [
            {
              "key" => "trading_post",
              "label" => "Trading Post",
              "action_type" => "open_feature",
              "feature" => "shop",
              "polygon" => [
                [237, 194], [205, 196], [141, 177], [86, 154], [85, 146],
                [108, 123], [189, 114], [219, 156], [221, 173], [238, 180]
              ]
            },
            {
              "key" => "exit",
              "label" => "Leave the village",
              "action_type" => "return_world",
              "polygon" => [
                [527, 235], [554, 238], [551, 245], [566, 243], [577, 239],
                [569, 227], [561, 218], [557, 224], [544, 213], [536, 210]
              ]
            }
          ]
        }
      }
    }
  end

  tile_buildings.each do |attrs|
    building = TileBuilding.find_or_initialize_by(building_key: attrs[:building_key])
    building.assign_attributes(
      zone: attrs[:zone],
      x: attrs[:x],
      y: attrs[:y],
      building_type: attrs[:building_type],
      name: attrs[:name],
      destination_zone: attrs[:destination_zone],
      destination_x: attrs[:destination_x],
      destination_y: attrs[:destination_y],
      icon: attrs[:icon],
      required_level: attrs[:required_level],
      active: true,
      metadata: attrs[:metadata] || {}
    )
    building.save!
    puts "  Created/Found TileBuilding: #{attrs[:name]}"
  end


  current_city_gate_keys = tile_buildings.pluck(:building_key)
  retired_city_gates = TileBuilding
    .where(building_key: %w[outpost_gate outpost_south_gate outpost_east_gate])
    .where.not(building_key: current_city_gate_keys)
  ApplicationRecord.transaction do
    retire_world_action_targets&.call("TileBuilding", retired_city_gates)
    retired_city_gates.destroy_all
  end
end

puts "Tile buildings seeding complete!"

# ============================================================
# CITY HOTSPOTS
# Captured actions for each city node
# ============================================================
puts "\n=== Seeding City Hotspots ==="

outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
city_zones_by_key = Game::World::CityCatalog::NODES.to_h do |node_key, node|
  [node_key, Zone.find_by(name: node["zone_name"])]
end
city_hotspots = []

Game::World::CityCatalog::NODES.each do |node_key, node|
  zone = city_zones_by_key[node_key]
  next unless zone

  node["links"].each do |destination_key, destination_name|
    city_hotspots << {
      zone:,
      key: "go_#{destination_key}",
      name: destination_name,
      hotspot_type: "district",
      action_type: "enter_zone",
      destination_zone: city_zones_by_key[destination_key],
      action_params: {"destination_x" => 0, "destination_y" => 0},
      required_level: 0
    }
  end

  node["features"].each do |feature_key, feature|
    city_hotspots << {
      zone:,
      key: feature_key,
      name: feature["name"],
      hotspot_type: "building",
      action_type: "open_feature",
      destination_zone: nil,
      action_params: {"feature" => feature_key},
      required_level: feature.fetch("required_level", 0)
    }
  end

  Game::World::CityCatalog::GATES.each do |gate_key, gate|
    next unless gate["node_key"] == node_key

    local_x, local_y = gate["local_coordinates"]
    city_hotspots << {
      zone:,
      key: "#{gate_key}_gate",
      name: gate["name"],
      hotspot_type: "exit",
      action_type: "enter_zone",
      destination_zone: outpost_surroundings,
      action_params: {
        "destination_x" => local_x,
        "destination_y" => local_y,
        "source_coordinates" => gate["source_coordinates"]
      },
      required_level: 0
    }
  end
end

seeded_hotspot_ids = city_hotspots.each_with_index.filter_map do |attrs, index|
  next unless attrs[:destination_zone] || attrs[:action_type] == "open_feature"

  hotspot = CityHotspot.find_or_initialize_by(zone: attrs[:zone], key: attrs[:key])
  hotspot.assign_attributes(
    name: attrs[:name],
    hotspot_type: attrs[:hotspot_type],
    position_x: 0,
    position_y: 0,
    width: nil,
    height: nil,
    image_normal: nil,
    image_hover: nil,
    action_type: attrs[:action_type],
    destination_zone: attrs[:destination_zone],
    action_params: attrs[:action_params] || {},
    required_level: attrs[:required_level] || 0,
    z_index: index,
    active: true
  )
  hotspot.save!
  puts "  Created/Found CityHotspot: #{attrs[:name]}"
  hotspot.id
end

city_zone_ids = city_zones_by_key.values.compact.map(&:id)
forpost_city_zone_ids = forpost_city_zones.map(&:id)
retired_city_zone_ids = forpost_city_zone_ids - city_zone_ids
stale_hotspots = CityHotspot.where(zone_id: forpost_city_zone_ids).where.not(id: seeded_hotspot_ids)

ApplicationRecord.transaction do
  if defined?(WorldActionOffer)
    live_statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
    WorldActionOffer.where(zone_id: retired_city_zone_ids, status: live_statuses).update_all(
      status: WorldActionOffer.statuses.fetch("cancelled"),
      error_message: "City layout was updated.",
      updated_at: Time.current
    )
  end

  retire_world_action_targets&.call("CityHotspot", stale_hotspots)

  central_square = city_zones_by_key[Game::World::CityCatalog::STARTER_NODE_KEY]
  if defined?(CharacterPosition) && central_square && retired_city_zone_ids.any?
    CharacterPosition.where(zone_id: retired_city_zone_ids).find_each do |position|
      position.update!(zone: central_square, x: 0, y: 0)
    end
  end

  stale_hotspots.destroy_all
end

puts "City hotspots seeding complete!"
