if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)
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
