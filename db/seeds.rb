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

def zone_metadata_for(name, biome)
  case name
  when "Outpost"
    {
      "default_movement_modifier" => "road",
      "exit_to" => "Outpost Surroundings"
    }
  when "Outpost Surroundings"
    {
      "default_movement_modifier" => "road",
      "source_map" => "m_1001_999"
    }
  else
    {
      "default_movement_modifier" => biome
    }
  end
end

if defined?(Zone)
  [
    {name: "Outpost", biome: "city", width: 10, height: 10},
    {name: "Outpost Surroundings", biome: "plains", width: 15, height: 15}
  ].each do |attrs|
    Zone.find_or_create_by!(name: attrs[:name]) do |zone|
      zone.biome = attrs[:biome]
      zone.width = attrs[:width]
      zone.height = attrs[:height]
      zone.metadata = zone_metadata_for(attrs[:name], attrs[:biome])
    end
  end
end

if defined?(SpawnPoint) && defined?(Zone)
  {
    "Outpost" => [{x: 5, y: 5, faction_key: "neutral", default_entry: true}],
    "Outpost Surroundings" => [{x: 7, y: 7, faction_key: "neutral", default_entry: true}]
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

if defined?(MapTileTemplate)
  # Starter city tiles. Detailed building services are exposed through
  # source-backed CityHotspot records instead of generic tile NPCs.
  city_tiles = []
  outpost = Zone.find_by(name: "Outpost")
  if outpost
    zone_name = outpost.name  # Store zone name as string, not the Zone object
    city_tiles << {zone: zone_name, x: 5, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "Town Square"}}
    city_tiles << {zone: zone_name, x: 6, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "Лавка"}}
    city_tiles << {zone: zone_name, x: 4, y: 5, terrain_type: "city", biome: "city", metadata: {"building" => "Arena"}}
    city_tiles << {zone: zone_name, x: 5, y: 9, terrain_type: "city", biome: "city", metadata: {"building" => "South Gate"}}
  end

  # Outpost Surroundings - captured outdoor map area with city return.
  plains = Zone.find_by(name: "Outpost Surroundings")
  plains_tiles = []
  if plains
    plains_name = plains.name  # Store zone name as string, not the Zone object
    (0..14).each do |x|
      (0..14).each do |y|
        tile_meta = {}
        terrain = "plains"

        # City entrance marker
        if x == 7 && y == 0
          tile_meta["building"] = "Road to Outpost"
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

  # Insert all tiles
  (city_tiles + plains_tiles).each do |attrs|
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

if defined?(ItemTemplate)
  # Source-backed NPC material item templates.
  material_items = [
    {key: "wood_chips", name: "Щепки", item_type: "material", rarity: "common", weight: 1},
    {key: "rat_tail", name: "Крысиный хвост", item_type: "material", rarity: "common", weight: 1}
  ]

  material_items.each do |attrs|
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
  puts "Created #{material_items.size} material item templates"
end

if defined?(CurrencyWallet)
  if admin
    wallet = admin.currency_wallet || CurrencyWallet.create!(user: admin)
    wallet.adjust!(currency: :gold, amount: 7_500, reason: "seed.initial_gold", metadata: {"source" => "starter_content"})
    wallet.adjust!(currency: :silver, amount: 1_200, reason: "seed.shop_sale")
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
  outpost = Zone.find_by(name: "Outpost")

  tile_buildings = []

  # City entrance from Starter Plains to Outpost
  if starter_plains && outpost
    tile_buildings << {
      zone: starter_plains.name,
      x: 7,
      y: 0,
      building_key: "outpost_gate",
      building_type: "city",
      name: "City Gates",
      destination_zone: outpost,
      destination_x: 5,
      destination_y: 9,
      icon: "🏙️",
      required_level: 1,
      metadata: {
        "description" => "Enter the starter city node."
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
outpost = Zone.find_by(name: "Outpost")
starter_plains = Zone.find_by(name: "Starter Plains")

if outpost
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
    zone: outpost,
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
    zone: outpost,
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

  # Лавка - documented Neverlands shop, pending Rails implementation
  # TODO: Adjust position to match shop location on city.png
  city_hotspots << {
    zone: outpost,
    key: "shop",
    name: "Лавка",
    hotspot_type: "building",
    position_x: 100,    # Left side (adjust to match your city.png)
    position_y: 350,
    width: 250,
    height: 200,
    image_hover: "shop.png",
    action_type: "open_feature",
    action_params: {"feature" => "shop"},
    required_level: 1,
    z_index: 20
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
  puts "  Skipping city hotspots: Outpost zone not found"
end

puts "City hotspots seeding complete!"
