lukin_user = nil

if defined?(User)
  admin = User.find_or_create_by!(email: "admin@elselands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)

  lukin_user = User.find_or_create_by!(email: "lukin.maksim@gmail.com") do |user|
    user.password = "password!"
    user.confirmed_at = Time.current
  end
  lukin_user.add_role(:admin)
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
      {
        name: "#{klass.name} Signature",
        kind: "active",
        resource_cost: {klass.resource_type => 20},
        effects: {
          damage: 25,
          debuffs: [{name: "Shattered Armor", duration: 2, stat_changes: {"defense" => -2}}]
        }
      },
      {
        name: "#{klass.name} Guard",
        kind: "reaction",
        resource_cost: {},
        effects: {
          status: "shield",
          buffs: [{name: "Guarding Stance", duration: 2, stat_changes: {"defense" => 5}}]
        }
      }
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
    Flipper.enable(feature)
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

def zone_metadata_for(name, biome)
  case name
  when "Castleton Keep"
    {
      "default_movement_modifier" => "road",
      "infirmary" => {"reduction_seconds" => 20}
    }
  else
    {
      "default_movement_modifier" => biome
    }
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
      zone.metadata = zone_metadata_for(attrs[:name], attrs[:biome])
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
    {key: "master_artisan", name: "Master Artisan", reward_type: "housing_trophy", reward_payload: {"trophy_name" => "Forgemaster Bust"}, category: "crafting"},
    {key: "legendary_artisan", name: "Legendary Artisan", reward_type: "title", reward_payload: {"title_key" => "legendary_artisan_title"}, category: "crafting"}
  ].each do |attrs|
    achievement = Achievement.find_or_initialize_by(key: attrs[:key])
    achievement.name = attrs[:name]
    achievement.reward_type = attrs[:reward_type]
    achievement.reward_payload = attrs[:reward_payload]
    achievement.category = attrs[:category] || "general"
    achievement.display_priority = attrs[:display_priority] || 0
    achievement.save!
  end
end

if defined?(Quest)
  [
    {key: "starter_crafting_tools", title: "Tools of the Trade", sequence: 1, quest_type: :side, chapter: 1,
     summary: "Tutorial quest for crafting systems."},
    {key: "profession_reset", title: "Reforge Your Path", sequence: 2, quest_type: :side, chapter: 1,
     summary: "Walkthrough for resetting profession choices."},
    {key: "movement_tutorial", title: "First Steps", sequence: 1, quest_type: :main_story, chapter: 0,
     summary: "Learn tile-based movement and turn actions."},
    {key: "combat_tutorial", title: "Trial by Combat", sequence: 2, quest_type: :main_story, chapter: 0,
     summary: "Covers initiative, PvE fights, and combat logs."},
    {key: "stat_allocation_tutorial", title: "Forging Your Build", sequence: 3, quest_type: :main_story, chapter: 0,
     summary: "Explains stat allocation and respec options."},
    {key: "gear_upgrade_tutorial", title: "Dress for Battle", sequence: 4, quest_type: :main_story, chapter: 0,
     summary: "Introduces equipment slots, weight, and enhancements."}
  ].each do |attrs|
    Quest.find_or_create_by!(key: attrs[:key]) do |quest|
      quest.title = attrs[:title]
      quest.sequence = attrs[:sequence]
      quest.quest_type = attrs[:quest_type]
      quest.chapter = attrs[:chapter]
      quest.summary = attrs[:summary]
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

if defined?(SocialHub)
  SocialHub.find_or_create_by!(slug: "castle-tavern") do |hub|
    hub.name = "Castleton Tavern"
    hub.hub_type = "tavern"
    hub.zone = Zone.find_by(name: "Castleton Keep")
    hub.metadata = {"description" => "Central hangout with notice board and minigames."}
  end
end

if defined?(GroupListing) && defined?(Guild)
  owner = User.first
  guild = Guild.first
  if owner && guild
    GroupListing.find_or_create_by!(owner:, title: "Evening Dungeon Run") do |listing|
      listing.description = "Looking for healers and ranged DPS for Frost Peaks delve."
      listing.listing_type = :party
      listing.status = :open
      listing.guild = guild
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
admin ||= User.find_by(email: "admin@elselands.test")
lukin_user ||= User.find_by(email: "lukin.maksim@gmail.com")

main_character = nil
secondary_character = nil
lukin_character = nil

if defined?(Character) && admin
  warrior = CharacterClass.find_by(name: "Warrior")
  mage = CharacterClass.find_by(name: "Mage")
  hunter = CharacterClass.find_by(name: "Hunter")

  if warrior
    main_character = Character.find_or_create_by!(user: admin, name: "Aldric Stormguard") do |char|
      char.character_class = warrior
      char.level = 22
      char.experience = 125_000
      char.faction_alignment = "alliance"
      char.alignment_score = 15
      char.reputation = 1_200
      char.allocated_stats = {"strength" => 16, "vitality" => 12, "agility" => 5}
      char.resource_pools = {"rage" => {"current" => 70, "max" => 110}}
      char.metadata = {"battlefield_roles" => %w[tank leader]}
    end
    main_character.reload
    main_character.inventory || main_character.create_inventory!(slot_capacity: 48, weight_capacity: 160)
  end

  if mage
    secondary_character = Character.find_or_create_by!(user: admin, name: "Lyra Dawnsong") do |char|
      char.character_class = mage
      char.level = 18
      char.experience = 82_000
      char.faction_alignment = "alliance"
      char.alignment_score = 6
      char.reputation = 640
      char.allocated_stats = {"intellect" => 18, "vitality" => 6, "agility" => 4}
      char.resource_pools = {"mana" => {"current" => 125, "max" => 150}}
      char.metadata = {"battlefield_roles" => %w[burst support]}
    end
    secondary_character.reload
    secondary_character.inventory || secondary_character.create_inventory!(slot_capacity: 42, weight_capacity: 130)
  end

  if hunter && lukin_user
    lukin_character = Character.find_or_create_by!(user: lukin_user, name: "Rovan Emberfall") do |char|
      char.character_class = hunter
      char.level = 16
      char.experience = 61_000
      char.faction_alignment = "rebellion"
      char.alignment_score = 2
      char.reputation = 480
      char.allocated_stats = {"agility" => 14, "strength" => 7, "vitality" => 5}
      char.resource_pools = {"focus" => {"current" => 90, "max" => 120}}
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
    item.slot = "weapon"
    item.rarity = "rare"
    item.stat_modifiers = {"attack" => 18, "crit" => 5}
    item.weight = 5
    item.enhancement_rules = {"base_success_chance" => 60, "required_skill_level" => 6}
  end

  elixir_template = ItemTemplate.find_or_create_by!(name: "Aetheric Elixir") do |item|
    item.slot = "consumable"
    item.rarity = "epic"
    item.stat_modifiers = {"intellect" => 6}
    item.weight = 1
    item.enhancement_rules = {"consumable" => true}
  end
end

if defined?(CraftingJob) && main_character
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

  alchemy_recipe = Recipe.find_by(name: "Aetheric Elixir")
  guild_station = CraftingStation.find_by(name: "Guild Hall Loom")
  if alchemy_recipe && guild_station && secondary_character
    completed_job = CraftingJob.find_or_initialize_by(
      character: secondary_character,
      recipe: alchemy_recipe,
      status: :completed
    )
    completed_job.user = admin
    completed_job.crafting_station = guild_station
    completed_job.batch_quantity = 1
    completed_job.started_at ||= 50.minutes.ago
    completed_job.completes_at ||= 35.minutes.ago
    completed_job.success_chance = 76
    completed_job.quality_score = 91
    completed_job.quality_tier = :epic
    completed_job.result_payload = {"items" => [{"name" => "Aetheric Elixir", "quantity" => 1, "quality" => "epic"}]}
    completed_job.portable_penalty_applied = false
    completed_job.save!
  end
end

if defined?(InventoryItem)
  if main_character&.inventory && (longsword_template = ItemTemplate.find_by(name: "Tempered Longsword"))
    InventoryItem.find_or_create_by!(inventory: main_character.inventory, item_template: longsword_template) do |item|
      item.quantity = 1
      item.weight = longsword_template.weight
      item.enhancement_level = 2
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

housing_plot = nil

if defined?(HousingPlot) && admin
  guild_id = admin.primary_guild&.id
  housing_plot = HousingPlot.find_or_create_by!(user: admin, location_key: "castleton_upper", plot_type: "townhome") do |plot|
    plot.plot_tier = "deluxe"
    plot.exterior_style = "aurora"
    plot.room_slots = 4
    plot.utility_slots = 2
    plot.storage_slots = 60
    plot.showcase_enabled = true
    plot.visit_scope = guild_id ? "guild" : "friends"
    plot.access_rules = {"friends_can_decorate" => true, "guild_ids" => Array(guild_id)}
    plot.upkeep_gold_cost = 450
    plot.next_upkeep_due_at = 3.days.from_now
  end
end

if defined?(HousingDecorItem) && housing_plot
  HousingDecorItem.find_or_create_by!(housing_plot:, name: "Forgemaster Bust Trophy") do |decor|
    decor.decor_type = :trophy
    decor.trophy = true
    decor.placement = {"room" => "atrium", "x" => 2, "y" => 1}
    decor.metadata = {"achievement_key" => "master_artisan", "lighting" => "ember"}
  end

  HousingDecorItem.find_or_create_by!(housing_plot:, name: "Arcane Anvil") do |decor|
    decor.decor_type = :utility
    decor.placement = {"room" => "workshop", "x" => 0, "y" => 0}
    decor.metadata = {"buff_key" => "crafting_speed", "bonus_percent" => 8}
    decor.utility_slot = 1
  end
end

if defined?(PetCompanion) && admin
  fox_species = PetSpecies.find_by(name: "Silver Fox")
  if fox_species
    PetCompanion.find_or_create_by!(user: admin, pet_species: fox_species) do |pet|
      pet.nickname = "Ember"
      pet.level = 7
      pet.bonding_experience = 360
      pet.affinity_stage = :friendly
      pet.gathering_bonus = 12
      pet.passive_bonus_type = "herbalism_speed"
      pet.passive_bonus_value = 5
      pet.care_state = {"last_task" => "moonlit-run"}
      pet.care_task_available_at = 1.hour.from_now
    end
  end
end

if defined?(MountStableSlot) && defined?(Mount) && admin
  slot = MountStableSlot.find_or_create_by!(user: admin, slot_index: 0) do |stable_slot|
    stable_slot.status = :active
    stable_slot.unlocked_at = 5.days.ago
    stable_slot.cosmetics = {"banners" => ["winter_festival"]}
  end

  mount = Mount.find_or_create_by!(user: admin, name: "Stormglide") do |m|
    m.mount_type = "gryphon"
    m.faction_key = "alliance"
    m.rarity = "epic"
    m.speed_bonus = 35
    m.summon_state = :summoned
    m.cosmetic_variant = "frostfeather"
    m.appearance = {"armour" => "silver", "trail" => "aurora"}
  end

  mount.update!(mount_stable_slot: slot)
  slot.update!(current_mount: mount) unless slot.current_mount_id == mount.id
end

if defined?(AchievementGrant) && admin
  %w[master_artisan legendary_artisan].each_with_index do |key, index|
    achievement = Achievement.find_by(key:)
    next unless achievement

    AchievementGrant.find_or_create_by!(user: admin, achievement:) do |grant|
      grant.source = "seed.story_reward"
      grant.granted_at = (index + 1).days.ago
    end
  end
end

if defined?(Title) && defined?(TitleGrant) && admin
  artisan_title = Title.find_or_create_by!(requirement_key: "legendary_artisan_title") do |title|
    title.name = "Legendary Artisan"
    title.perks = {"housing_storage_bonus" => 10, "crafting_quality_bonus" => 3}
    title.priority_party_finder = true
  end

  TitleGrant.find_or_create_by!(user: admin, title: artisan_title) do |grant|
    grant.source = "achievement.legendary_artisan"
    grant.granted_at = 1.day.ago
    grant.equipped = true
  end

  admin.update!(active_title: artisan_title) if admin.respond_to?(:active_title=)
end

admin_wallet = nil

if defined?(CurrencyWallet)
  if admin
    admin_wallet = admin.currency_wallet || CurrencyWallet.create!(user: admin)
    admin_wallet.adjust!(currency: :gold, amount: 7_500, reason: "seed.story_reward", metadata: {"source" => "winter_festival"})
    admin_wallet.adjust!(currency: :gold, amount: -350, reason: "sink.housing_upkeep", metadata: {"housing_plot_id" => housing_plot&.id})
    admin_wallet.adjust!(currency: :silver, amount: 1_200, reason: "seed.market_sale", metadata: {"item" => "Tempered Longsword"})
    admin_wallet.adjust!(currency: :premium_tokens, amount: 40, reason: "seed.founders_pack")
  end

  if lukin_user
    wallet = lukin_user.currency_wallet || CurrencyWallet.create!(user: lukin_user)
    wallet.adjust!(currency: :gold, amount: 4_200, reason: "seed.pvp_rewards")
    wallet.adjust!(currency: :gold, amount: -600, reason: "sink.auction_bid", metadata: {"item" => "Tempered Longsword"})
    wallet.adjust!(currency: :silver, amount: 800, reason: "seed.trade_posting")
  end
end

if defined?(PremiumTokenLedgerEntry) && admin_wallet
  PremiumTokenLedgerEntry.find_or_create_by!(user: admin, entry_type: :purchase, reason: "founders.pack") do |entry|
    entry.delta = 40
    entry.balance_after = admin_wallet.premium_tokens_balance
    entry.metadata = {"source" => "seed"}
  end
end

if defined?(AuctionListing) && defined?(AuctionBid) && admin && lukin_user
  listing = AuctionListing.find_or_create_by!(seller: admin, item_name: "Tempered Longsword") do |auction|
    auction.currency_type = "gold"
    auction.status = :active
    auction.location_key = "castleton_market"
    auction.quantity = 1
    auction.starting_bid = 1_200
    auction.buyout_price = 2_200
    auction.ends_at = 6.hours.from_now
    auction.item_metadata = {"rarity" => "rare", "item_type" => "weapon", "stats" => {"attack" => 18}}
  end

  AuctionBid.find_or_create_by!(auction_listing: listing, bidder: lukin_user) do |bid|
    bid.amount = 1_500
  end
end

event_instance = nil

if defined?(EventInstance) && defined?(GameEvent)
  festival_event = GameEvent.find_by(slug: "winter_festival")
  if festival_event
    event_instance = EventInstance.find_or_create_by!(game_event: festival_event, status: :active) do |instance|
      instance.starts_at = 1.day.ago
      instance.ends_at = 6.days.from_now
      instance.announcer_npc_key = "captain_elara"
      instance.metadata = {"featured_quest_key" => "movement_tutorial", "bonus_rewards" => ["winter_token"]}
    end
    unless event_instance.starts_at
      event_instance.update!(
        starts_at: 1.day.ago,
        ends_at: 6.days.from_now,
        metadata: event_instance.metadata.merge("featured_quest_key" => "movement_tutorial")
      )
    end
  end
end

if defined?(CommunityObjective) && event_instance
  CommunityObjective.find_or_create_by!(event_instance:, resource_key: "donated_ice_shards") do |objective|
    objective.title = "Reinforce the Ice Sculptures"
    objective.goal_amount = 10_000
    objective.current_amount = 6_450
    objective.status = :tracking
    objective.metadata = {
      "top_contributors" => [
        {"user" => admin&.email, "amount" => 1_200},
        {"user" => lukin_user&.email, "amount" => 640}
      ],
      "checkpoint_rewards" => {"2500" => "festival_fireworks", "7500" => "housing_banner"}
    }
  end
end

if defined?(Announcement) && event_instance
  Announcement.find_or_create_by!(title: "Winter Festival Live!") do |announcement|
    announcement.body = <<~BODY
      The Winter Festival event instance #{event_instance.id} is now active in Castleton Keep.
      Donate ice shards to reinforce the sculptures, chase limited quests, and unlock the Stormglide gryphon cosmetic variant.
    BODY
  end
end

if defined?(QuestAssignment) && main_character
  in_progress_quest = Quest.find_by(key: "movement_tutorial")
  completed_quest = Quest.find_by(key: "combat_tutorial")
  failed_quest = Quest.find_by(key: "gear_upgrade_tutorial")

  if in_progress_quest
    assignment = QuestAssignment.find_or_create_by!(quest: in_progress_quest, character: main_character)
    assignment.update!(
      status: :in_progress,
      started_at: 2.hours.ago,
      expires_at: 1.day.from_now,
      progress: {"current_step_position" => 3, "decisions" => {"bridge" => "ambush-route"}},
      metadata: {"story_flags" => ["met_scout"], "branch" => "shadow_path"}
    )
  end

  if completed_quest
    completed_assignment = QuestAssignment.find_or_create_by!(quest: completed_quest, character: main_character)
    completed_assignment.update!(
      status: :completed,
      started_at: 5.hours.ago,
      completed_at: 2.hours.ago,
      rewards_claimed_at: 90.minutes.ago,
      progress: {"current_step_position" => 5, "completed" => true, "decisions" => {"arena" => "parley"}},
      metadata: {"story_flags" => ["trained_with_captain"], "branch" => "valor"}
    )
  end

  if failed_quest
    failed_assignment = QuestAssignment.find_or_create_by!(quest: failed_quest, character: main_character)
    failed_assignment.update!(
      status: :failed,
      started_at: 1.day.ago,
      abandoned_at: 12.hours.ago,
      abandon_reason: "timed_out",
      progress: {"current_step_position" => 2, "failure_step" => 2, "decisions" => {"forge" => "delay"}},
      metadata: {
        "story_flags" => ["missed_patrol"],
        "branch" => "reckless",
        "event_instance_id" => event_instance&.id,
        "failure_report" => {"cause" => "breach", "npc" => "Captain Elara"}
      }
    )
  end
end

if defined?(QuestAnalyticsSnapshot)
  QuestAnalyticsSnapshot.find_or_create_by!(captured_on: Date.current, quest_chain_key: "main_story") do |snapshot|
    snapshot.completion_rate = 82.5
    snapshot.abandon_rate = 12.0
    snapshot.avg_completion_minutes = 26
    snapshot.bottleneck_step_key = "gear_upgrade_tutorial.step2"
    snapshot.bottleneck_step_position = 2
    snapshot.metadata = {
      "event_instance_id" => event_instance&.id,
      "top_branches" => {"valor" => 58, "shadow_path" => 31},
      "failure_examples" => [{"quest_key" => "gear_upgrade_tutorial", "reason" => "timed_out"}]
    }
  end
end
