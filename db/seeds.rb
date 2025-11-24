lukin_user = nil

if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)

  lukin_user = User.find_or_create_by!(email: "lukin.maksim@gmail.com") do |user|
    user.password = "password!"
    user.confirmed_at = Time.current
  end
end

if defined?(ClassSpecialization) && defined?(CharacterClass)
  {
    "Warrior" => [
      {name: "Paladin", description: "Shielded crusader", unlock_requirements: {quest: "holy_trial"}}
    ],
    "Thief" => [
      {name: "Assassin", description: "Shadow finisher", unlock_requirements: {quest: "daggerfall"}}
    ]
  }.each do |class_name, specs|
    klass = CharacterClass.find_by(name: class_name)
    next unless klass

    specs.each do |spec_attrs|
      ClassSpecialization.find_or_create_by!(character_class: klass, name: spec_attrs[:name]) do |spec|
        spec.description = spec_attrs[:description]
        spec.unlock_requirements = spec_attrs[:unlock_requirements]
      end
    end
  end
end

if defined?(SkillTree) && defined?(SkillNode)
  CharacterClass.find_each do |klass|
    tree = SkillTree.find_or_create_by!(character_class: klass, name: "#{klass.name} Core") do |skill_tree|
      skill_tree.description = "Signature abilities for #{klass.name}"
    end

    [
      {key: "#{klass.name.parameterize}_tier1", name: "#{klass.name} Training", node_type: "passive", tier: 1, effects: {attack: 2}},
      {key: "#{klass.name.parameterize}_ultimate", name: "#{klass.name} Ultimate", node_type: "ultimate", tier: 3, effects: {special: true}, requirements: {level: 30}}
    ].each do |node_attrs|
      SkillNode.find_or_create_by!(skill_tree: tree, key: node_attrs[:key]) do |node|
        node.name = node_attrs[:name]
        node.node_type = node_attrs[:node_type]
        node.tier = node_attrs[:tier]
        node.effects = node_attrs[:effects]
        node.requirements = node_attrs[:requirements] || {}
      end
    end
  end
end

if defined?(Ability)
  CharacterClass.find_each do |klass|
    [
      {name: "#{klass.name} Signature", kind: "active", resource_cost: {klass.resource_type => 20}, effects: {damage: 25}},
      {name: "#{klass.name} Guard", kind: "reaction", resource_cost: {}, effects: {status: "shield"}}
    ].each do |ability_attrs|
      Ability.find_or_create_by!(character_class: klass, name: ability_attrs[:name]) do |ability|
        ability.kind = ability_attrs[:kind]
        ability.resource_cost = ability_attrs[:resource_cost]
        ability.effects = ability_attrs[:effects]
      end
    end
  end
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

  if lukin_user
    Flipper.disable(:combat_system, lukin_user)
    Flipper.disable(:housing, lukin_user)
    Flipper.disable(:guilds, lukin_user)
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
    {name: "Blacksmithing", category: "production", metadata: {reset_cost_tokens: 200}},
    {name: "Alchemy", category: "production", metadata: {reset_cost_tokens: 150}},
    {name: "Herbalism", category: "gathering", gathering: true, gathering_resource: "herb", metadata: {reset_cost_tokens: 100}},
    {name: "Fishing", category: "gathering", gathering: true, gathering_resource: "fish", metadata: {reset_cost_tokens: 100}},
    {name: "Doctor", category: "support", description: "Battlefield medic", healing_bonus: 20, metadata: {reset_cost_tokens: 250}}
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
    {name: "Whispering Woods Field Kit", city: "Whispering Woods", station_type: "field_kit", capacity: 1, station_archetype: :field_kit, portable: true, time_penalty_multiplier: 1.4, success_penalty: 10},
    {name: "Guild Hall Loom", city: "Castleton Keep", station_type: "loom", capacity: 3, station_archetype: :guild_hall, success_penalty: 0}
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
  alchemy = Profession.find_by(name: "Alchemy")
  if smith
    Recipe.find_or_create_by!(profession: smith, name: "Tempered Longsword") do |recipe|
      recipe.tier = 2
      recipe.duration_seconds = 180
      recipe.output_item_name = "Tempered Longsword"
      recipe.requirements = {"skill_level" => 5, "materials" => {"Iron Ingot" => 4, "Coal Chunk" => 1}, "tool_wear" => 8}
      recipe.rewards = {"items" => [{"name" => "Tempered Longsword", "quantity" => 1}]}
      recipe.source_kind = :quest
      recipe.risk_level = :moderate
      recipe.required_station_archetype = :city
      recipe.quality_modifiers = {"city_bonus" => 5}
    end
  end
  if alchemy
    Recipe.find_or_create_by!(profession: alchemy, name: "Aetheric Elixir") do |recipe|
      recipe.tier = 3
      recipe.duration_seconds = 240
      recipe.output_item_name = "Aetheric Elixir"
      recipe.requirements = {
        "skill_level" => 8,
        "materials" => {"Moonleaf" => 2, "Riverwater" => 1},
        "tool_wear" => 5,
        "success_penalty" => 5
      }
      recipe.rewards = {"items" => [{"name" => "Aetheric Elixir", "quantity" => 1}]}
      recipe.source_kind = :guild_research
      recipe.risk_level = :risky
      recipe.premium_token_cost = 5
      recipe.required_station_archetype = :guild_hall
      recipe.quality_modifiers = {"legendary_threshold" => 95}
      recipe.guild_bound = true
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

if defined?(Zone)
  [
    {name: "Castleton Keep", biome: "city", width: 10, height: 10},
    {name: "Whispering Woods", biome: "forest", width: 12, height: 12},
    {name: "Frost Peaks", biome: "mountain", width: 8, height: 8}
  ].each do |attrs|
    Zone.find_or_create_by!(name: attrs[:name]) do |zone|
      zone.biome = attrs[:biome]
      zone.width = attrs[:width]
      zone.height = attrs[:height]
      zone.encounter_table = {}
      zone.metadata = {}
    end
  end
end

if defined?(SpawnPoint) && defined?(Zone)
  {
    "Castleton Keep" => [{x: 0, y: 0, faction_key: "neutral", default_entry: true}],
    "Whispering Woods" => [{x: 0, y: 0, faction_key: "rebellion", respawn_seconds: 90}],
    "Frost Peaks" => [{x: 2, y: 2, faction_key: "alliance", respawn_seconds: 120}]
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

if defined?(Achievement)
  [
    {key: "master_artisan", name: "Master Artisan", reward_type: "housing_trophy", reward_payload: {"trophy_name" => "Forgemaster Bust"}},
    {key: "legendary_artisan", name: "Legendary Artisan", reward_type: "title", reward_payload: {"title" => "Artisan of Legends"}}
  ].each do |attrs|
    Achievement.find_or_create_by!(key: attrs[:key]) do |achievement|
      achievement.name = attrs[:name]
      achievement.reward_type = attrs[:reward_type]
      achievement.reward_payload = attrs[:reward_payload]
    end
  end
end

if defined?(Quest)
  [
    {key: "starter_crafting_tools", title: "Tools of the Trade", sequence: 1, quest_type: :side, chapter: 1},
    {key: "profession_reset", title: "Reforge Your Path", sequence: 2, quest_type: :side, chapter: 1}
  ].each do |attrs|
    Quest.find_or_create_by!(key: attrs[:key]) do |quest|
      quest.title = attrs[:title]
      quest.sequence = attrs[:sequence]
      quest.quest_type = attrs[:quest_type]
      quest.chapter = attrs[:chapter]
      quest.summary = "Tutorial quest for crafting systems."
    end
  end
end

if defined?(GuildMission)
  guild = Guild.first
  profession = Profession.find_by(name: "Blacksmithing")
  if guild && profession
    GuildMission.find_or_create_by!(guild:, required_profession: profession, required_item_name: "Tempered Longsword") do |mission|
      mission.required_quantity = 10
      mission.status = :active
      mission.metadata = {"reward" => "guild_xp"}
    end
  end
end

if defined?(CharacterClass)
  [
    {
      name: "Warrior",
      description: "Front-line fighter with high vitality and shield combos.",
      resource_type: "rage",
      equipment_tags: %w[weapon shield armor],
      base_stats: {strength: 8, vitality: 7, agility: 4, intellect: 2}
    },
    {
      name: "Mage",
      description: "Arcane caster wielding mana-fueled spells.",
      resource_type: "mana",
      equipment_tags: %w[weapon robe accessory],
      base_stats: {strength: 2, vitality: 3, agility: 4, intellect: 9}
    },
    {
      name: "Hunter",
      description: "Ranged specialist with traps and companions.",
      resource_type: "focus",
      equipment_tags: %w[weapon offhand leather],
      base_stats: {strength: 5, vitality: 4, agility: 8, intellect: 3}
    },
    {
      name: "Priest",
      description: "Support caster balancing heals and wards.",
      resource_type: "faith",
      equipment_tags: %w[weapon accessory robe],
      base_stats: {strength: 3, vitality: 5, agility: 3, intellect: 8}
    },
    {
      name: "Thief",
      description: "Stealth assassin chaining combo finishers.",
      resource_type: "energy",
      equipment_tags: %w[weapon offhand leather],
      base_stats: {strength: 6, vitality: 4, agility: 9, intellect: 2}
    }
  ].each do |attrs|
    CharacterClass.find_or_create_by!(name: attrs[:name]) do |klass|
      klass.description = attrs[:description]
      klass.base_stats = attrs[:base_stats]
      klass.resource_type = attrs[:resource_type]
      klass.equipment_tags = attrs[:equipment_tags]
      klass.combo_rules = {max_chain: 3}
    end
  end
end

if defined?(ItemTemplate)
  [
    {
      name: "Iron Longsword",
      slot: "weapon",
      rarity: "common",
      stat_modifiers: {attack: 6},
      weight: 4
    },
    {
      name: "Oak Longbow",
      slot: "weapon",
      rarity: "uncommon",
      stat_modifiers: {attack: 5, agility: 2},
      weight: 3
    },
    {
      name: "Mystic Robes",
      slot: "head",
      rarity: "rare",
      stat_modifiers: {intellect: 4, vitality: 2},
      weight: 1,
      premium: true
    }
  ].each do |attrs|
    ItemTemplate.find_or_create_by!(name: attrs[:name]) do |item|
      item.slot = attrs[:slot]
      item.rarity = attrs[:rarity]
      item.stat_modifiers = attrs[:stat_modifiers]
      item.weight = attrs[:weight] || 2
      item.premium = attrs.fetch(:premium, false)
      item.enhancement_rules = {"base_success_chance" => 55, "required_skill_level" => 5, "failure_penalty" => "downgrade"}
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
    {zone: "Castleton Keep", x: 0, y: 0, terrain_type: "plaza", passable: true, biome: "city"},
    {zone: "Castleton Keep", x: 1, y: 0, terrain_type: "barracks", passable: true, biome: "city"},
    {zone: "Castleton Keep", x: -1, y: 0, terrain_type: "armory", passable: true, biome: "city"},
    {zone: "Whispering Woods", x: 0, y: 0, terrain_type: "grove", passable: true, biome: "forest", metadata: {encounters: [{"name" => "Forest Wisp", "weight" => 50}]}},
    {zone: "Whispering Woods", x: 1, y: 0, terrain_type: "bog", passable: false, biome: "forest"},
    {zone: "Whispering Woods", x: 0, y: 1, terrain_type: "trail", passable: true, biome: "forest"}
  ].each do |attrs|
    MapTileTemplate.find_or_create_by!(zone: attrs[:zone], x: attrs[:x], y: attrs[:y]) do |tile|
      tile.terrain_type = attrs[:terrain_type]
      tile.passable = attrs.fetch(:passable, true)
      tile.metadata = attrs.fetch(:metadata, {})
      tile.biome = attrs.fetch(:biome, "plains")
    end
  end
end
