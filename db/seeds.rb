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

if defined?(Profession)
  [
    {name: "Blacksmithing", category: "production"},
    {name: "Alchemy", category: "production"},
    {name: "Herbalism", category: "gathering", gathering: true, gathering_resource: "herb"},
    {name: "Fishing", category: "gathering", gathering: true, gathering_resource: "fish"},
    {name: "Doctor", category: "support", description: "Battlefield medic", healing_bonus: 20}
  ].each do |attrs|
    Profession.find_or_create_by!(name: attrs[:name]) do |profession|
      profession.category = attrs[:category]
      profession.gathering = attrs.fetch(:gathering, false)
      profession.gathering_resource = attrs[:gathering_resource]
      profession.healing_bonus = attrs.fetch(:healing_bonus, 0)
      profession.description = attrs[:description]
      profession.metadata = attrs[:metadata] || {}
    end
  end
end

if defined?(CraftingStation)
  [
    {name: "Castleton Forge", city: "Castleton Keep", station_type: "forge", capacity: 4, station_archetype: :city},
    {name: "Whispering Woods Field Kit", city: "Whispering Woods", station_type: "field_kit", capacity: 1, station_archetype: :field_kit, portable: true, time_penalty_multiplier: 1.4, success_penalty: 10}
  ].each do |attrs|
    CraftingStation.find_or_create_by!(name: attrs[:name]) do |station|
      station.city = attrs[:city]
      station.station_type = attrs[:station_type]
      station.capacity = attrs[:capacity]
      station.station_archetype = attrs[:station_archetype]
      station.portable = attrs.fetch(:portable, false)
      station.time_penalty_multiplier = attrs.fetch(:time_penalty_multiplier, 1.0)
      station.success_penalty = attrs.fetch(:success_penalty, 0)
      station.metadata = {}
    end
  end
end

if defined?(Recipe)
  smith = Profession.find_by(name: "Blacksmithing")
  if smith
    Recipe.find_or_create_by!(profession: smith, name: "Tempered Longsword") do |recipe|
      recipe.tier = 2
      recipe.duration_seconds = 180
      recipe.output_item_name = "Tempered Longsword"
      recipe.requirements = {"skill_level" => 5, "materials" => {"Iron Ingot" => 4, "Coal Chunk" => 1}, "tool_wear" => 8}
      recipe.rewards = {"items" => [{"name" => "Tempered Longsword", "quantity" => 1}]}
      recipe.source_kind = :vendor
      recipe.risk_level = :moderate
      recipe.required_station_archetype = :city
      recipe.quality_modifiers = {"city_bonus" => 5}
    end
  end
end

def zone_metadata_for(name, biome)
  case name
  when "Castleton Keep"
    {
      "default_movement_modifier" => "road",
      "infirmary" => {"reduction_seconds" => 20},
      "exit_to" => "Starter Plains"
    }
  when "Starter Plains"
    {
      "default_movement_modifier" => "road",
      "encounter_rate" => 0.15
    }
  else
    {
      "default_movement_modifier" => biome,
      "encounter_rate" => 0.2
    }
  end
end

if defined?(Zone)
  [
    {name: "Castleton Keep", biome: "city", width: 10, height: 10},
    {name: "Starter Plains", biome: "plains", width: 15, height: 15},
    {name: "Whispering Woods", biome: "forest", width: 12, height: 12},
    {name: "Frost Peaks", biome: "mountain", width: 8, height: 8}
  ].each do |attrs|
    Zone.find_or_create_by!(name: attrs[:name]) do |zone|
      zone.biome = attrs[:biome]
      zone.width = attrs[:width]
      zone.height = attrs[:height]
      zone.encounter_table = {}
      zone.metadata = zone_metadata_for(attrs[:name], attrs[:biome])
    end
  end
end

if defined?(SpawnPoint) && defined?(Zone)
  {
    "Castleton Keep" => [{x: 5, y: 5, faction_key: "neutral", default_entry: true}],
    "Starter Plains" => [{x: 7, y: 7, faction_key: "neutral", default_entry: true}],
    "Whispering Woods" => [{x: 0, y: 0, faction_key: "rebellion", respawn_seconds: 90, default_entry: true}],
    "Frost Peaks" => [{x: 2, y: 2, faction_key: "alliance", respawn_seconds: 120, default_entry: true}]
  }.each do |zone_name, points|
    zone = Zone.find_by(name: zone_name)
    next unless zone

    points.each do |point|
      SpawnPoint.find_or_create_by!(zone:, x: point[:x], y: point[:y]) do |spawn|
        spawn.faction_key = point[:faction_key]
        spawn.city_key = zone_name.parameterize
        spawn.respawn_seconds = point[:respawn_seconds] || 60
        spawn.default_entry = point.fetch(:default_entry, false)
      end
    end
  end
end

if defined?(GatheringNode) && defined?(Profession)
  herbalism = Profession.find_by(name: "Herbalism")
  zone = Zone.find_by(name: "Whispering Woods")
  if herbalism && zone
    GatheringNode.find_or_create_by!(profession: herbalism, zone: zone, resource_key: "moonleaf") do |node|
      node.difficulty = 3
      node.respawn_seconds = 45
      node.rewards = {"moonleaf" => 1, "glowcap" => 0.2}
    end
  end
end

if defined?(ItemTemplate)
  [
    {
      name: "Iron Longsword",
      item_type: "equipment",
      slot: "main_hand",
      rarity: "common",
      stat_modifiers: {attack: 6},
      weight: 4
    },
    {
      name: "Oak Longbow",
      item_type: "equipment",
      slot: "main_hand",
      rarity: "uncommon",
      stat_modifiers: {attack: 5, dexterity: 2},
      weight: 3
    },
    {
      name: "Mystic Robes",
      item_type: "equipment",
      slot: "chest",
      rarity: "rare",
      stat_modifiers: {intelligence: 4, vitality: 2},
      weight: 1
    }
  ].each do |attrs|
    ItemTemplate.find_or_create_by!(name: attrs[:name]) do |item|
      item.item_type = attrs[:item_type]
      item.slot = attrs[:slot]
      item.rarity = attrs[:rarity]
      item.stat_modifiers = attrs[:stat_modifiers]
      item.weight = attrs[:weight] || 2
      item.stack_limit = attrs[:stack_limit] || 1
    end
  end
end

if defined?(NpcTemplate)
  [
    {
      name: "Captain Elara",
      level: 20,
      role: "guard",
      dialogue: "Elselands needs defenders. Will you answer the call?",
      metadata: {zone: "Castleton Keep"}
    },
    {
      name: "Merrit the Merchant",
      level: 5,
      role: "vendor",
      dialogue: "Coins for wares, traveler. Best prices this side of the realm.",
      metadata: {inventory: %w[health_potion mana_potion]}
    },
    {
      name: "Rhuven the Hermit",
      level: 15,
      role: "lore",
      dialogue: "The forest whispers secrets to those who listen.",
      metadata: {zone: "Whispering Woods"}
    }
  ].each do |attrs|
    NpcTemplate.find_or_create_by!(name: attrs[:name]) do |npc|
      npc.level = attrs[:level]
      npc.role = attrs[:role]
      npc.dialogue = attrs[:dialogue]
      npc.metadata = attrs[:metadata]
    end
  end
end

if defined?(MapTileTemplate)
  # Castleton Keep - City tiles with buildings and NPCs
  city_tiles = []
  castleton = Zone.find_by(name: "Castleton Keep")
  if castleton
    zone_name = castleton.name  # Store zone name as string, not the Zone object
    # Central plaza
    city_tiles << {zone: zone_name, x: 5, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "Town Square"}}
    city_tiles << {zone: zone_name, x: 4, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "Blacksmith", "npc" => "Smith Gorn"}}
    city_tiles << {zone: zone_name, x: 6, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "General Store", "npc" => "Merchant Elara"}}
    city_tiles << {zone: zone_name, x: 5, y: 4, terrain_type: "city", biome: "city", metadata: {"building" => "Tavern", "npc" => "Innkeeper Bram"}}
    city_tiles << {zone: zone_name, x: 4, y: 4, terrain_type: "city", biome: "city", metadata: {"npc" => "Guard Captain"}}
    city_tiles << {zone: zone_name, x: 6, y: 4, terrain_type: "city", biome: "city", metadata: {"building" => "Bank"}}
    # Walls and gates
    city_tiles << {zone: zone_name, x: 5, y: 9, terrain_type: "city", biome: "city", metadata: {"building" => "South Gate"}}
    city_tiles << {zone: zone_name, x: 5, y: 0, terrain_type: "city", biome: "city", metadata: {"building" => "North Gate"}}
  end

  # Starter Plains - Outdoor area with resources, NPCs, and terrain variety
  plains = Zone.find_by(name: "Starter Plains")
  plains_tiles = []
  if plains
    plains_name = plains.name  # Store zone name as string, not the Zone object
    # Generate a variety of terrain
    (0..14).each do |x|
      (0..14).each do |y|
        tile_meta = {}
        terrain = "plains"

        # Add rivers (horizontal stripe)
        if y == 10 && x.between?(3, 11)
          terrain = "river"
          tile_meta["blocked"] = true if x != 7 # Bridge at x=7
          tile_meta["building"] = "Stone Bridge" if x == 7
        # Lake
        elsif x.between?(11, 13) && y.between?(3, 5)
          terrain = "lake"
          tile_meta["blocked"] = true
          tile_meta["resource"] = "Fishing Spot" if x == 11 && y == 4
          tile_meta["resource_type"] = "fish" if x == 11 && y == 4
        # Forest patches
        elsif (x.between?(1, 3) && y.between?(2, 4)) || (x.between?(10, 12) && y.between?(11, 13))
          terrain = "forest"
          # Add wood resources in forests
          if rand < 0.3
            tile_meta["resource"] = "Oak Tree"
            tile_meta["resource_type"] = "wood"
          end
        # Mountain areas
        elsif x.between?(0, 2) && y.between?(12, 14)
          terrain = "mountain"
          tile_meta["blocked"] = true if x == 0 || y == 14
          if rand < 0.3 && !tile_meta["blocked"]
            tile_meta["resource"] = "Iron Deposit"
            tile_meta["resource_type"] = "ore"
          end
        end

        # Add herbs scattered around plains
        if terrain == "plains" && rand < 0.1
          tile_meta["resource"] = "Wild Herbs"
          tile_meta["resource_type"] = "herb"
        end

        # Add enemy NPCs in certain areas (not near spawn)
        distance_from_spawn = Math.sqrt((x - 7)**2 + (y - 7)**2)
        if terrain == "plains" && distance_from_spawn > 4 && rand < 0.08
          enemies = ["Wild Wolf", "Forest Boar", "Bandit Scout", "Giant Rat"]
          tile_meta["npc"] = enemies.sample
        end

        # Add friendly NPCs
        if x == 7 && y == 3
          tile_meta["npc"] = "Wandering Trader"
        elsif x == 3 && y == 8
          tile_meta["npc"] = "Old Hermit"
          tile_meta["building"] = "Hermit's Hut"
        end

        # City entrance marker
        if x == 7 && y == 0
          tile_meta["building"] = "Road to Castleton"
        end

        plains_tiles << {
          zone: plains_name,
          x: x,
          y: y,
          terrain_type: terrain,
          biome: terrain,
          passable: !tile_meta["blocked"],
          metadata: tile_meta
        }
      end
    end
  end

  # Whispering Woods - Dense forest with resources and enemies
  woods = Zone.find_by(name: "Whispering Woods")
  woods_tiles = []
  if woods
    woods_name = woods.name  # Store zone name as string, not the Zone object
    (0..11).each do |x|
      (0..11).each do |y|
        tile_meta = {}
        terrain = "forest"

        # Dense impassable areas
        if (x == 0 || x == 11 || y == 0 || y == 11) && rand < 0.4
          tile_meta["blocked"] = true
        end

        # Swamp area
        if x.between?(7, 10) && y.between?(7, 10)
          terrain = "swamp"
          if rand < 0.2
            tile_meta["resource"] = "Swamp Moss"
            tile_meta["resource_type"] = "herb"
          end
        end

        # Enemy spawns
        distance_from_entrance = Math.sqrt(x**2 + y**2)
        if distance_from_entrance > 3 && rand < 0.12 && !tile_meta["blocked"]
          enemies = ["Forest Wisp", "Giant Spider", "Corrupted Treant", "Shadow Wolf"]
          tile_meta["npc"] = enemies.sample
        end

        # Resources
        if terrain == "forest" && rand < 0.15 && !tile_meta["blocked"] && !tile_meta["npc"]
          resources = [
            {name: "Moonleaf", type: "herb"},
            {name: "Ancient Oak", type: "wood"},
            {name: "Glowing Mushroom", type: "herb"}
          ]
          res = resources.sample
          tile_meta["resource"] = res[:name]
          tile_meta["resource_type"] = res[:type]
        end

        woods_tiles << {
          zone: woods_name,
          x: x,
          y: y,
          terrain_type: terrain,
          biome: terrain,
          passable: !tile_meta["blocked"],
          metadata: tile_meta
        }
      end
    end
  end

  # Insert all tiles
  (city_tiles + plains_tiles + woods_tiles).each do |attrs|
    next unless attrs[:zone]
    MapTileTemplate.find_or_create_by!(zone: attrs[:zone], x: attrs[:x], y: attrs[:y]) do |tile|
      tile.terrain_type = attrs[:terrain_type]
      tile.passable = attrs.fetch(:passable, true)
      tile.metadata = attrs.fetch(:metadata, {})
      tile.biome = attrs.fetch(:biome, "plains")
    end
  end
end

if defined?(ArenaSeason)
  ArenaSeason.find_or_create_by!(slug: "founders-season") do |season|
    season.name = "Founders Season"
    season.status = :live
    season.starts_at = 1.week.ago
    season.ends_at = 1.month.from_now
    season.metadata = {"description" => "Launch window ranked play."}
  end
end

# ------------------------------------------------------------------
# Gameplay feature sandboxes used by flow + feature documentation
# ------------------------------------------------------------------
# Use the users created at the top of the file (first@lukin.io, second@lukin.io)
# Fall back to alternative emails if those don't exist
admin ||= User.find_by(email: "first@lukin.io") || User.find_by(email: "admin@elselands.test")
lukin_user ||= User.find_by(email: "second@lukin.io") || User.find_by(email: "lukin.maksim@gmail.com")

main_character = nil
secondary_character = nil
lukin_character = nil

if defined?(Character) && admin
  main_character = Character.find_or_create_by!(user: admin, name: "Aldric Stormguard") do |char|
    char.level = 22
    char.experience = 125_000
    char.faction_alignment = "alliance"
    char.alignment_score = 15
    char.reputation = 1_200
    char.allocated_stats = {"strength" => 16, "vitality" => 12, "dexterity" => 5}
    char.resource_pools = {"fatigue" => 0}
    char.metadata = {"battlefield_roles" => %w[frontline leader]}
  end
  main_character.reload
  main_character.inventory || main_character.create_inventory!(slot_capacity: 48, weight_capacity: 160)

  secondary_character = Character.find_or_create_by!(user: admin, name: "Lyra Dawnsong") do |char|
    char.level = 18
    char.experience = 82_000
    char.faction_alignment = "alliance"
    char.alignment_score = 6
    char.reputation = 640
    char.allocated_stats = {"intelligence" => 18, "vitality" => 6, "dexterity" => 4}
    char.resource_pools = {"fatigue" => 0}
    char.metadata = {"battlefield_roles" => %w[magic support]}
  end
  secondary_character.reload
  secondary_character.inventory || secondary_character.create_inventory!(slot_capacity: 42, weight_capacity: 130)

  if lukin_user
    lukin_character = Character.find_or_create_by!(user: lukin_user, name: "Rovan Emberfall") do |char|
      char.level = 16
      char.experience = 61_000
      char.faction_alignment = "rebellion"
      char.alignment_score = 2
      char.reputation = 480
      char.allocated_stats = {"dexterity" => 14, "strength" => 7, "vitality" => 5}
      char.resource_pools = {"fatigue" => 0}
      char.metadata = {"battlefield_roles" => %w[scout archer]}
    end
    lukin_character.reload
    lukin_character.inventory || lukin_character.create_inventory!(slot_capacity: 36, weight_capacity: 140)
  end
end

if defined?(ProfessionProgress) && main_character
  smithing = Profession.find_by(name: "Blacksmithing")
  herbalism = Profession.find_by(name: "Herbalism")

  if smithing
    ProfessionProgress.find_or_create_by!(character: main_character, profession: smithing) do |progress|
      progress.user = admin
      progress.skill_level = 9
      progress.experience = 420
      progress.slot_kind = "primary"
      progress.metadata = {"buff_bonus" => 12, "specializations" => ["weaponry"]}
    end
  end

  if herbalism
    ProfessionProgress.find_or_create_by!(character: main_character, profession: herbalism) do |progress|
      progress.user = admin
      progress.skill_level = 5
      progress.experience = 180
      progress.slot_kind = "gathering"
      progress.metadata = {"trail_bonus" => 8, "foraging_route" => "whispering_woods"}
    end
  end
end

if defined?(ItemTemplate)
  longsword_template = ItemTemplate.find_or_create_by!(name: "Tempered Longsword") do |item|
    item.item_type = "equipment"
    item.slot = "main_hand"
    item.rarity = "rare"
    item.stat_modifiers = {"attack" => 18, "crit" => 5}
    item.weight = 5
    item.stack_limit = 1
  end

  elixir_template = ItemTemplate.find_or_create_by!(name: "Aetheric Elixir") do |item|
    item.item_type = "consumable"
    item.slot = "none"
    item.rarity = "epic"
    item.stat_modifiers = {"intelligence" => 6}
    item.weight = 1
    item.stack_limit = 99
  end

  # Resource/Material Item Templates (for gathering)
  resource_items = [
    # Ore resources
    {key: "iron_ore", name: "Iron Ore", item_type: "material", rarity: "common", weight: 3},
    {key: "copper_ore", name: "Copper Ore", item_type: "material", rarity: "common", weight: 3},
    {key: "gold_vein", name: "Gold Vein", item_type: "material", rarity: "uncommon", weight: 4},
    {key: "silver_ore", name: "Silver Ore", item_type: "material", rarity: "uncommon", weight: 3},
    {key: "mythril_ore", name: "Mythril Ore", item_type: "material", rarity: "epic", weight: 2},
    {key: "bog_iron", name: "Bog Iron", item_type: "material", rarity: "common", weight: 3},
    {key: "river_stone", name: "River Stone", item_type: "material", rarity: "common", weight: 2},
    # Wood resources
    {key: "wood_chips", name: "Щепки", item_type: "material", rarity: "common", weight: 1},
    {key: "oak_wood", name: "Oak Wood", item_type: "material", rarity: "common", weight: 2},
    {key: "birch_wood", name: "Birch Wood", item_type: "material", rarity: "common", weight: 2},
    {key: "ancient_oak", name: "Ancient Oak", item_type: "material", rarity: "rare", weight: 3},
    # Herb resources
    {key: "healing_herb", name: "Healing Herb", item_type: "material", rarity: "common", weight: 1},
    {key: "moonleaf_herb", name: "Moonleaf Herb", item_type: "material", rarity: "uncommon", weight: 1},
    {key: "wild_berries", name: "Wild Berries", item_type: "material", rarity: "common", weight: 1},
    {key: "flax_plant", name: "Flax Plant", item_type: "material", rarity: "uncommon", weight: 1},
    {key: "mountain_herb", name: "Mountain Herb", item_type: "material", rarity: "uncommon", weight: 1},
    {key: "swamp_moss", name: "Swamp Moss", item_type: "material", rarity: "common", weight: 1},
    {key: "poison_bloom", name: "Poison Bloom", item_type: "material", rarity: "uncommon", weight: 1},
    {key: "glowing_mushroom", name: "Glowing Mushroom", item_type: "material", rarity: "uncommon", weight: 1},
    {key: "water_lily", name: "Water Lily", item_type: "material", rarity: "common", weight: 1},
    {key: "wild_plant", name: "Wild Plant", item_type: "material", rarity: "common", weight: 1},
    # Crystal/gem resources
    {key: "crystal_formation", name: "Crystal Formation", item_type: "material", rarity: "rare", weight: 1},
    {key: "swamp_gas_crystal", name: "Swamp Gas Crystal", item_type: "material", rarity: "rare", weight: 1},
    {key: "river_pearl", name: "River Pearl", item_type: "material", rarity: "rare", weight: 1},
    # Fish resources
    {key: "common_fish", name: "Common Fish", item_type: "material", rarity: "common", weight: 2},
    {key: "golden_carp", name: "Golden Carp", item_type: "material", rarity: "uncommon", weight: 2},
    {key: "freshwater_clam", name: "Freshwater Clam", item_type: "material", rarity: "uncommon", weight: 1}
  ]

  resource_items.each do |attrs|
    ItemTemplate.find_or_create_by!(key: attrs[:key]) do |item|
      item.name = attrs[:name]
      item.item_type = attrs[:item_type]
      item.slot = "material"
      item.rarity = attrs[:rarity]
      item.weight = attrs[:weight]
      item.stack_limit = 99
      item.stat_modifiers = {}
    end
  end
  puts "Created #{resource_items.size} resource item templates"
end

if defined?(CraftingJob) && main_character
  CraftingJob.suppressing_turbo_broadcasts do
    smith_recipe = Recipe.find_by(name: "Tempered Longsword")
    forge = CraftingStation.find_by(name: "Castleton Forge")
    if smith_recipe && forge
      active_job = CraftingJob.find_or_initialize_by(
        character: main_character,
        recipe: smith_recipe,
        status: :in_progress
      )
      active_job.user = admin
      active_job.crafting_station = forge
      active_job.batch_quantity = 2
      active_job.started_at ||= 10.minutes.ago
      active_job.completes_at = 5.minutes.from_now
      active_job.success_chance = 82
      active_job.quality_score = 84
      active_job.quality_tier = :rare
      active_job.result_payload = {"preview" => {"items" => [{"name" => "Tempered Longsword", "quantity" => 2, "quality" => "rare"}]}}
      active_job.portable_penalty_applied = false
      active_job.save!
    end
  end
end

if defined?(InventoryItem)
  if main_character&.inventory && (longsword_template = ItemTemplate.find_by(name: "Tempered Longsword"))
    InventoryItem.find_or_create_by!(inventory: main_character.inventory, item_template: longsword_template) do |item|
      item.quantity = 1
      item.weight = longsword_template.weight
      item.properties = {"crafted_by" => "Aldric", "quality_score" => 84}
      item.slot_kind = "weapon"
    end
  end

  if secondary_character&.inventory && (elixir_template = ItemTemplate.find_by(name: "Aetheric Elixir"))
    InventoryItem.find_or_create_by!(inventory: secondary_character.inventory, item_template: elixir_template) do |item|
      item.quantity = 2
      item.weight = elixir_template.weight
      item.properties = {"batch_id" => "winter-festival-brew", "quality_score" => 91}
      item.slot_kind = "consumable"
    end
  end
end

if defined?(CurrencyWallet)
  if admin
    wallet = admin.currency_wallet || CurrencyWallet.create!(user: admin)
    wallet.adjust!(currency: :gold, amount: 7_500, reason: "seed.initial_gold", metadata: {"source" => "starter_content"})
    wallet.adjust!(currency: :silver, amount: 1_200, reason: "seed.shop_sale", metadata: {"item" => "Tempered Longsword"})
  end

  if lukin_user
    wallet = lukin_user.currency_wallet || CurrencyWallet.create!(user: lukin_user)
    wallet.adjust!(currency: :gold, amount: 4_200, reason: "seed.arena_rewards")
    wallet.adjust!(currency: :silver, amount: 800, reason: "seed.shop_sale")
  end
end

# ==============================================================================
# Arena Rooms
# ==============================================================================
puts "Seeding Arena Rooms..."

if defined?(ArenaRoom)
  arena_rooms = [
    {
      name: "Training Grounds",
      slug: "training",
      room_type: :training,
      level_min: 1,
      level_max: 10,
      faction_restriction: nil,
      description: "Practice arena for new combatants. Low stakes, all welcome."
    },
    {
      name: "Trial Hall",
      slug: "trial",
      room_type: :trial,
      level_min: 5,
      level_max: 20,
      faction_restriction: nil,
      description: "Prove your worth in serious combat. Medium trauma fights."
    },
    {
      name: "Challenge Arena",
      slug: "challenge",
      room_type: :challenge,
      level_min: 15,
      level_max: 40,
      faction_restriction: nil,
      description: "For seasoned warriors. High stakes combat."
    },
    {
      name: "Initiation Chamber",
      slug: "initiation",
      room_type: :initiation,
      level_min: 10,
      level_max: 25,
      faction_restriction: nil,
      description: "Initiation rites for combatants."
    },
    {
      name: "Hall of Light",
      slug: "light",
      room_type: :light,
      level_min: 20,
      level_max: 60,
      faction_restriction: "light",
      description: "Champions of Light fight for honor and justice."
    },
    {
      name: "Shadow Pit",
      slug: "dark",
      room_type: :dark,
      level_min: 20,
      level_max: 60,
      faction_restriction: "dark",
      description: "The forces of Darkness test their strength here."
    },
    {
      name: "Balance Sanctum",
      slug: "balance",
      room_type: :balance,
      level_min: 20,
      level_max: 60,
      faction_restriction: "neutral",
      description: "Neutral warriors maintain equilibrium through combat."
    },
    {
      name: "Chaos Coliseum",
      slug: "chaos",
      room_type: :chaos,
      level_min: 30,
      level_max: 80,
      faction_restriction: nil,
      description: "Free-for-all mayhem. Anything goes. High trauma!"
    },
    {
      name: "Patron's Throne Room",
      slug: "patron",
      room_type: :patron,
      level_min: 50,
      level_max: 100,
      faction_restriction: nil,
      description: "Elite arena for high-level patrons and champions."
    },
    {
      name: "Hall of Law",
      slug: "law",
      room_type: :law,
      level_min: 25,
      level_max: 70,
      faction_restriction: nil,
      description: "Judicial combat to settle disputes and honor duels."
    }
  ]

  arena_rooms.each do |room_data|
    ArenaRoom.find_or_create_by!(slug: room_data[:slug]) do |room|
      room.name = room_data[:name]
      room.room_type = room_data[:room_type]
      room.level_min = room_data[:level_min]
      room.level_max = room_data[:level_max]
      room.faction_restriction = room_data[:faction_restriction]
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
  starter_plains = Zone.find_by(name: "Starter Plains")
  castleton = Zone.find_by(name: "Castleton Keep")
  whispering_woods = Zone.find_by(name: "Whispering Woods")

  tile_buildings = []

  # Castle entrance from Starter Plains to Castleton Keep
  if starter_plains && castleton
    tile_buildings << {
      zone: starter_plains.name,
      x: 7,
      y: 0,
      building_key: "castleton_gate",
      building_type: "castle",
      name: "Castleton Keep Gates",
      destination_zone: castleton,
      destination_x: 5,
      destination_y: 9,
      icon: "🏰",
      required_level: 1,
      metadata: {
        "description" => "The main gates to Castleton Keep, home to the Alliance forces."
      }
    }
  end

  # Exit from Castleton Keep back to Starter Plains
  if castleton && starter_plains
    tile_buildings << {
      zone: castleton.name,
      x: 5,
      y: 9,
      building_key: "castleton_exit",
      building_type: "portal",
      name: "City Gates",
      destination_zone: starter_plains,
      destination_x: 7,
      destination_y: 1,
      icon: "🚪",
      required_level: 1,
      metadata: {
        "description" => "Exit the city walls to the Starter Plains."
      }
    }
  end

  # Inn in Castleton Keep
  if castleton
    tile_buildings << {
      zone: castleton.name,
      x: 3,
      y: 3,
      building_key: "castleton_inn",
      building_type: "inn",
      name: "The Wanderer's Rest",
      destination_zone: nil,  # No zone transition, but shows on map
      icon: "🏨",
      required_level: 1,
      metadata: {
        "description" => "A cozy inn for weary travelers. Rest here to restore vitality."
      }
    }
  end

  tile_buildings.each do |attrs|
    TileBuilding.find_or_create_by!(building_key: attrs[:building_key]) do |building|
      building.zone = attrs[:zone]
      building.x = attrs[:x]
      building.y = attrs[:y]
      building.building_type = attrs[:building_type]
      building.name = attrs[:name]
      building.destination_zone = attrs[:destination_zone]
      building.destination_x = attrs[:destination_x]
      building.destination_y = attrs[:destination_y]
      building.icon = attrs[:icon]
      building.required_level = attrs[:required_level]
      building.active = true
      building.metadata = attrs[:metadata] || {}
    end
    puts "  Created/Found TileBuilding: #{attrs[:name]}"
  end
end

puts "Tile buildings seeding complete!"

# ============================================================
# CITY HOTSPOTS
# Interactive building hotspots for city illustrated view
# ============================================================
puts "\n=== Seeding City Hotspots ==="

# Find existing zones
castleton = Zone.find_by(name: "Castleton Keep")
starter_plains = Zone.find_by(name: "Starter Plains")

if castleton
  city_hotspots = []

  # ==========================================================================
  # CITY HOTSPOT POSITIONING GUIDE
  # ==========================================================================
  # - city.png is 1536x1024 pixels
  # - Each overlay image (arena.png, gate.png, etc.) is also 1536x1024 with
  #   transparent areas except for the highlighted building
  # - position_x/y: Where to place the HITBOX (invisible clickable area)
  #   This should be the top-left corner of the building's clickable area
  # - width/height: Size of the HITBOX (clickable area)
  #   Adjust these to match the building's dimensions on city.png
  #
  # HOW TO FIND POSITIONS:
  # 1. Open city.png in an image editor
  # 2. Find the building you want to make clickable
  # 3. Note the top-left pixel coordinates (position_x, position_y)
  # 4. Measure the building's width and height in pixels
  # ==========================================================================

  # City Gates / Exit - leads back to Starter Plains
  # TODO: Adjust position to match gate location on city.png
  city_hotspots << {
    zone: castleton,
    key: "city_gate",
    name: "City Gates",
    hotspot_type: "exit",
    position_x: 680,    # Center-bottom area (adjust to match your city.png)
    position_y: 850,
    width: 180,
    height: 150,
    image_hover: "gate.png",
    action_type: "enter_zone",
    destination_zone: starter_plains,
    action_params: {"destination_x" => 7, "destination_y" => 0},
    required_level: 1,
    z_index: 10
  }

  # Arena - for player, team, and NPC fights
  # TODO: Adjust position to match arena location on city.png
  city_hotspots << {
    zone: castleton,
    key: "arena",
    name: "Arena",
    hotspot_type: "building",
    position_x: 1050,   # Right side (adjust to match your city.png)
    position_y: 200,
    width: 300,
    height: 250,
    image_hover: "arena.png",
    action_type: "open_feature",
    action_params: {"feature" => "arena"},
    required_level: 5,
    z_index: 20
  }

  # Workshop - for crafting
  # TODO: Adjust position to match workshop location on city.png
  city_hotspots << {
    zone: castleton,
    key: "workshop",
    name: "Workshop",
    hotspot_type: "building",
    position_x: 100,    # Left side (adjust to match your city.png)
    position_y: 350,
    width: 250,
    height: 200,
    image_hover: "workshop.png",
    action_type: "open_feature",
    action_params: {"feature" => "crafting"},
    required_level: 1,
    z_index: 20
  }

  # Clinic / Hospital - for healing
  # TODO: Adjust position to match clinic location on city.png
  city_hotspots << {
    zone: castleton,
    key: "clinic",
    name: "Clinic",
    hotspot_type: "building",
    position_x: 1150,   # Right side, lower (adjust to match your city.png)
    position_y: 500,
    width: 200,
    height: 180,
    image_hover: "clinic.png",
    action_type: "open_feature",
    action_params: {"feature" => "healing"},
    required_level: 1,
    z_index: 20
  }

  # Decorative Tree - no action, just hover effect
  # NOTE: tree.png is 1024x1536 (rotated) - may need different handling
  # TODO: Adjust position to match tree location on city.png
  city_hotspots << {
    zone: castleton,
    key: "tree_center",
    name: "Ancient Oak",
    hotspot_type: "decoration",
    position_x: 750,    # Center area (adjust to match your city.png)
    position_y: 550,
    width: 150,
    height: 200,
    image_hover: "tree.png",
    action_type: "none",
    z_index: 5
  }

  city_hotspots.each do |attrs|
    CityHotspot.find_or_create_by!(zone: attrs[:zone], key: attrs[:key]) do |hotspot|
      hotspot.name = attrs[:name]
      hotspot.hotspot_type = attrs[:hotspot_type]
      hotspot.position_x = attrs[:position_x]
      hotspot.position_y = attrs[:position_y]
      hotspot.width = attrs[:width]
      hotspot.height = attrs[:height]
      hotspot.image_normal = nil  # Not used - overlay approach uses full-size images
      hotspot.image_hover = attrs[:image_hover]
      hotspot.action_type = attrs[:action_type]
      hotspot.destination_zone = attrs[:destination_zone]
      hotspot.action_params = attrs[:action_params] || {}
      hotspot.required_level = attrs[:required_level] || 1
      hotspot.z_index = attrs[:z_index] || 0
      hotspot.active = true
    end
    puts "  Created/Found CityHotspot: #{attrs[:name]}"
  end
else
  puts "  Skipping city hotspots: Castleton Keep zone not found"
end

puts "City hotspots seeding complete!"
