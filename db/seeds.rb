if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)
end

if defined?(Role)
  %i[player moderator gm admin].each do |role_name|
    Role.find_or_create_by!(name: role_name)
  end
end

if defined?(Flipper)
  %i[combat_system guilds housing].each do |feature|
    Flipper.add(feature)
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
    {name: "Herbalism", category: "gathering", gathering: true},
    {name: "Fishing", category: "gathering", gathering: true}
  ].each do |attrs|
    Profession.find_or_create_by!(name: attrs[:name]) do |profession|
      profession.category = attrs[:category]
      profession.gathering = attrs.fetch(:gathering, false)
    end
  end
end

if defined?(PetSpecies)
  PetSpecies.find_or_create_by!(name: "Silver Fox") do |species|
    species.ability_type = "gathering_bonus"
    species.rarity = "rare"
    species.ability_payload = {"gather_bonus" => 0.05}
  end
end

if defined?(GameEvent)
  GameEvent.find_or_create_by!(slug: "winter_festival") do |event|
    event.name = "Winter Festival"
    event.description = "Seasonal quests and cosmetics."
    event.status = :upcoming
    event.starts_at = 1.month.from_now
    event.ends_at = 1.month.from_now + 2.weeks
  end
end

if defined?(CharacterClass)
  [
    {
      name: "Warrior",
      description: "Front-line fighter with high vitality and physical defense.",
      base_stats: {strength: 8, vitality: 7, agility: 4, intellect: 2}
    },
    {
      name: "Arcanist",
      description: "Master of destructive spells with fragile defenses.",
      base_stats: {strength: 2, vitality: 3, agility: 4, intellect: 9}
    },
    {
      name: "Ranger",
      description: "Mobile scout specializing in ranged attacks and traps.",
      base_stats: {strength: 5, vitality: 4, agility: 8, intellect: 3}
    }
  ].each do |attrs|
    CharacterClass.find_or_create_by!(name: attrs[:name]) do |klass|
      klass.description = attrs[:description]
      klass.base_stats = attrs[:base_stats]
    end
  end
end

if defined?(ItemTemplate)
  [
    {
      name: "Iron Longsword",
      slot: "weapon",
      rarity: "common",
      stat_modifiers: {attack: 6}
    },
    {
      name: "Oak Longbow",
      slot: "weapon",
      rarity: "uncommon",
      stat_modifiers: {attack: 5, agility: 2}
    },
    {
      name: "Mystic Robes",
      slot: "armor",
      rarity: "rare",
      stat_modifiers: {intellect: 4, vitality: 2}
    }
  ].each do |attrs|
    ItemTemplate.find_or_create_by!(name: attrs[:name]) do |item|
      item.slot = attrs[:slot]
      item.rarity = attrs[:rarity]
      item.stat_modifiers = attrs[:stat_modifiers]
    end
  end
end

if defined?(NpcTemplate)
  [
    {
      name: "Captain Elara",
      level: 20,
      role: "quest_giver",
      dialogue: "Neverlands needs defenders. Will you answer the call?",
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
  [
    {zone: "Castleton Keep", x: 0, y: 0, terrain_type: "plaza", passable: true},
    {zone: "Castleton Keep", x: 1, y: 0, terrain_type: "barracks", passable: true},
    {zone: "Castleton Keep", x: -1, y: 0, terrain_type: "armory", passable: true},
    {zone: "Whispering Woods", x: 0, y: 0, terrain_type: "grove", passable: true, metadata: {encounter: "forest_wisp"}},
    {zone: "Whispering Woods", x: 1, y: 0, terrain_type: "bog", passable: false},
    {zone: "Whispering Woods", x: 0, y: 1, terrain_type: "trail", passable: true}
  ].each do |attrs|
    MapTileTemplate.find_or_create_by!(zone: attrs[:zone], x: attrs[:x], y: attrs[:y]) do |tile|
      tile.terrain_type = attrs[:terrain_type]
      tile.passable = attrs.fetch(:passable, true)
      tile.metadata = attrs.fetch(:metadata, {})
    end
  end
end
