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
  case name
  when "Outpost"
    {
      "exit_to" => "Окрестность Форпоста"
    }
  when "Окрестность Форпоста"
    {
      "source_map" => "m_1001_999"
    }
  else
    {}
  end
end

if defined?(Zone)
  [
    {name: "Outpost", location_type: "city", width: 10, height: 10},
    {name: "Окрестность Форпоста", location_type: "outdoor", width: 15, height: 15}
  ].each do |attrs|
    Zone.find_or_create_by!(name: attrs[:name]) do |zone|
      zone.location_type = attrs[:location_type]
      zone.width = attrs[:width]
      zone.height = attrs[:height]
      zone.metadata = zone_metadata_for(attrs[:name])
    end
  end
end

if defined?(SpawnPoint) && defined?(Zone)
  {
    "Outpost" => [{x: 5, y: 5, default_entry: true}],
    "Окрестность Форпоста" => [{x: 7, y: 7, default_entry: true}]
  }.each do |zone_name, points|
    zone = Zone.find_by(name: zone_name)
    next unless zone

    points.each do |point|
      SpawnPoint.find_or_create_by!(zone:, x: point[:x], y: point[:y]) do |spawn|
        spawn.city_key = zone_name.parameterize
        spawn.default_entry = point.fetch(:default_entry, false)
      end
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
    city_tiles << {zone: zone_name, x: 5, y: 5, terrain_type: "city", metadata: {"building" => "Town Square"}}
    city_tiles << {zone: zone_name, x: 6, y: 5, terrain_type: "city", metadata: {"building" => "Лавка"}}
    city_tiles << {zone: zone_name, x: 4, y: 5, terrain_type: "city", metadata: {"building" => "Arena"}}
    city_tiles << {zone: zone_name, x: 5, y: 9, terrain_type: "city", metadata: {"building" => "South Gate"}}
  end

  # Окрестность Форпоста - captured outdoor map area with city return.
  outpost_surroundings = Zone.find_by(name: "Окрестность Форпоста")
  outdoor_tiles = []
  if outpost_surroundings
    outdoor_zone_name = outpost_surroundings.name  # Store zone name as string, not the Zone object
    (0..14).each do |x|
      (0..14).each do |y|
        tile_meta = {}
        terrain = "outdoor"

        # City entrance marker
        if x == 7 && y == 0
          tile_meta["building"] = "Road to Outpost"
        end

        outdoor_tiles << {
          zone: outdoor_zone_name,
          x: x,
          y: y,
          terrain_type: terrain,
          passable: !tile_meta["blocked"],
          metadata: tile_meta
        }
      end
    end
  end

  # Insert all tiles
  (city_tiles + outdoor_tiles).each do |attrs|
    next unless attrs[:zone]
    MapTileTemplate.find_or_create_by!(zone: attrs[:zone], x: attrs[:x], y: attrs[:y]) do |tile|
      tile.terrain_type = attrs[:terrain_type]
      tile.passable = attrs.fetch(:passable, true)
      tile.metadata = attrs.fetch(:metadata, {})
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
    {key: "wood_chips", name: "Щепки", item_type: "material", weight: 1},
    {key: "rat_tail", name: "Крысиный хвост", item_type: "material", weight: 1}
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
      name: "Тренировочный Зал",
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
  outpost_surroundings = Zone.find_by(name: "Окрестность Форпоста")
  outpost = Zone.find_by(name: "Outpost")

  tile_buildings = []

  # City entrance from Окрестность Форпоста to Outpost
  if outpost_surroundings && outpost
    tile_buildings << {
      zone: outpost_surroundings.name,
      x: 7,
      y: 0,
      building_key: "outpost_gate",
      building_type: "city",
      name: "Ворота Форпоста",
      destination_zone: outpost,
      destination_x: 5,
      destination_y: 9,
      icon: "🏙️",
      required_level: 1,
      metadata: {
        "description" => "Enter Форпост."
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

outpost = Zone.find_by(name: "Outpost")
outpost_surroundings = Zone.find_by(name: "Окрестность Форпоста")

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

  # Outpost gate / Exit - leads back to Окрестность Форпоста.
  city_hotspots << {
    zone: outpost,
    key: "city_gate",
    name: "Ворота Форпоста",
    hotspot_type: "exit",
    position_x: 680,
    position_y: 850,
    width: 180,
    height: 150,
    image_hover: "gate.png",
    action_type: "enter_zone",
    destination_zone: outpost_surroundings,
    action_params: {"destination_x" => 7, "destination_y" => 0},
    required_level: 1,
    z_index: 10
  }

  # Arena - for player, team, and NPC fights
  city_hotspots << {
    zone: outpost,
    key: "arena",
    name: "Arena",
    hotspot_type: "building",
    position_x: 1050,
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
  city_hotspots << {
    zone: outpost,
    key: "shop",
    name: "Лавка",
    hotspot_type: "building",
    position_x: 100,
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
