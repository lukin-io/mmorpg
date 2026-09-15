# frozen_string_literal: true

# Helpers for inventory views.
module InventoriesHelper
  INVENTORY_CATEGORIES = [
    ["all", "All"],
    ["things", "Things"],
    ["elixirs", "Elixirs"],
    ["alchemy", "Alchemy"],
    ["fishing", "Fishing"],
    ["hunting", "Hunt & Food"],
    ["resources", "Resources"],
    ["wood", "Wood"],
    ["quests", "Quest Journal"]
  ].freeze

  THINGS_SUBCATEGORIES = [
    ["all", "All"],
    ["knives", "Knives"],
    ["swords", "Swords"],
    ["axes", "Axes"],
    ["blunt", "Blunt"],
    ["polearms", "Halberds & Spears"],
    ["staves", "Staves"],
    ["shields", "Shields"],
    ["armor", "Armor"],
    ["helmets", "Helmets"],
    ["boots", "Boots"],
    ["pants", "Pants"],
    ["belts", "Belts"],
    ["gloves", "Gloves"],
    ["bracers", "Bracers"],
    ["jewelry", "Jewelry"],
    ["relics", "Relics"],
    ["scrolls", "Scrolls"],
    ["potions", "Potions"],
    ["quest_items", "Quest Items"],
    ["books", "Magic Books"],
    ["aid_kits", "Aid Kits"],
    ["runes", "Runes"]
  ].freeze

  FAMILY_EMPTY_STATES = {
    "elixirs" => "You carry no elixirs.",
    "quests" => "No active quests.",
    "all" => "No items in this category.",
    "things" => "No things in this category."
  }.freeze

  FAMILY_SECTIONS = {
    "alchemy" => [
      ["Alchemy Inventory", "No alchemy inventory items available.", true],
      ["Alchemy Resources", "No alchemy resources available.", true]
    ],
    "fishing" => [
      ["Fishing Inventory", "No fishing inventory items available.", true],
      ["Alchemy Resources", "No alchemy resources available.", true]
    ],
    "hunting" => [
      ["Cooking Inventory", "No cooking inventory items available.", true],
      ["Resources", "No resources available.", true]
    ],
    "resources" => [
      ["Resources", "No resources available.", true]
    ],
    "wood" => [
      ["Carpentry Inventory", "No carpentry inventory items available.", true],
      ["Resources", "No resources available.", true]
    ]
  }.freeze

  SLOT_ICONS = {
    head: "Helm",
    amulet: "Neck",
    main_hand: "Wpn",
    belt: "Belt",
    belt_1: "B1",
    belt_2: "B2",
    belt_3: "B3",
    feet: "Boot",
    pocket: "Pckt",
    pocket_1: "P1",
    bracers: "Brac",
    hands: "Glove",
    off_hand: "Shield",
    ring_1: "R1",
    ring_2: "R2",
    ring_3: "R3",
    ring_4: "R4",
    chest: "Armor",
    legs: "Pants",
    relic: "Relic"
  }.freeze

  ITEM_TYPE_ICONS = {
    "equipment" => "EQ",
    "weapon" => "WP",
    "armor" => "AR",
    "accessory" => "AC",
    "consumable" => "EL",
    "material" => "RS",
    "misc" => "IT"
  }.freeze

  ITEM_ARTWORK_PATHS = {
    "fist_attack" => "items/fist_attack.png",
    "penknife" => "items/penknife.png",
    "assassin_dagger" => "items/assassin_dagger.png",
    "butcher_cleaver" => "items/butcher_cleaver.png",
    "hunter_knife" => "items/hunter_knife.png",
    "mage_dagger" => "items/mage_dagger.png",
    "action_blade" => "items/action_blade.png",
    "sensation_sword" => "items/sensation_sword.png",
    "double_blade" => "items/double_blade.png",
    "curved_blade" => "items/curved_blade.png",
    "smile_sword" => "items/smile_sword.png",
    "woodcutter_axe" => "items/woodcutter_axe.png",
    "search_axe" => "items/search_axe.png",
    "cleaving_axe" => "items/cleaving_axe.png",
    "prosperity_axe" => "items/prosperity_axe.png",
    "distortion_axe" => "items/distortion_axe.png",
    "townsman_club" => "items/townsman_club.png",
    "apprentice_hammer" => "items/apprentice_hammer.png",
    "steel_club" => "items/steel_club.png",
    "steppe_sword" => "items/steppe_sword.png",
    "war_pick" => "items/war_pick.png",
    "beginner_healer_bag" => "items/healer_bag.png",
    "skilled_healer_bag" => "items/healer_bag.png",
    "experienced_healer_bag" => "items/healer_bag.png",
    "combat_first_aid_kit" => "items/healer_bag.png",
    "minor_health_potion" => "items/minor_health_potion.png",
    "primitive_spear" => "items/primitive_spear.png",
    "parrying_spear" => "items/parrying_spear.png",
    "pilum" => "items/pilum.png",
    "adventurer_spear" => "items/adventurer_spear.png",
    "trident" => "items/trident.png",
    "small_earthly_blessings_staff" => "items/small_earthly_blessings_staff.png",
    "small_crescent_staff" => "items/small_crescent_staff.png",
    "small_aspiration_staff" => "items/small_aspiration_staff.png",
    "small_power_staff" => "items/small_power_staff.png",
    "earthly_blessings_staff" => "items/earthly_blessings_staff.png",
    "advantage_shield" => "items/advantage_shield.png",
    "stubborn_shield" => "items/stubborn_shield.png",
    "grim_shield" => "items/grim_shield.png",
    "dew_shield" => "items/dew_shield.png",
    "possibility_shield" => "items/possibility_shield.png",
    "caution_armor" => "items/caution_armor.png",
    "assassin_suit" => "items/assassin_suit.png",
    "salvation_jacket" => "items/salvation_jacket.png",
    "life_shirt" => "items/life_shirt.png",
    "knowledge_shirt" => "items/knowledge_shirt.png",
    "leather_cap" => "items/leather_cap.png",
    "earflap_hat" => "items/earflap_hat.png",
    "hunter_helmet" => "items/hunter_helmet.png",
    "bandit_helmet" => "items/bandit_helmet.png",
    "spellcaster_cap" => "items/spellcaster_cap.png",
    "peasant_boots" => "items/peasant_boots.png",
    "military_boots" => "items/military_boots.png",
    "hunter_boots" => "items/hunter_boots.png",
    "petty_thief_sandals" => "items/petty_thief_sandals.png",
    "mage_apprentice_shoes" => "items/mage_apprentice_shoes.png",
    "worn_pants" => "items/worn_pants.png",
    "peasant_trousers" => "items/peasant_trousers.png",
    "hunter_trousers" => "items/hunter_trousers.png",
    "recruit_chainmail_pants" => "items/recruit_chainmail_pants.png",
    "leather_breeches" => "items/leather_breeches.png",
    "advantage_belt" => "items/advantage_belt.png",
    "thick_leather_belt" => "items/thick_leather_belt.png",
    "thin_leather_belt" => "items/thin_leather_belt.png",
    "diamond_sash" => "items/diamond_sash.png",
    "emerald_sash" => "items/emerald_sash.png",
    "dexterity_gloves" => "items/dexterity_gloves.png",
    "strength_gloves" => "items/strength_gloves.png",
    "luck_gloves" => "items/luck_gloves.png",
    "spellcaster_gloves" => "items/spellcaster_gloves.png",
    "quick_strike_gloves" => "items/quick_strike_gloves.png",
    "leather_bracers" => "items/leather_bracers.png",
    "congealed_blood_bracers" => "items/congealed_blood_bracers.png",
    "development_bracers" => "items/development_bracers.png",
    "stability_bracers" => "items/stability_bracers.png",
    "truth_bracers" => "items/truth_bracers.png",
    "salvation_pendant" => "items/salvation_pendant.png",
    "small_life_ring" => "items/small_life_ring.png",
    "small_protection_ring" => "items/small_protection_ring.png",
    "small_knowledge_ring" => "items/small_knowledge_ring.png",
    "subtlety_ring" => "items/subtlety_ring.png",
    "duel_permit_i" => "items/duel_permit_i.png",
    "duel_permit_ii" => "items/duel_permit_ii.png",
    "duel_permit_iii" => "items/duel_permit_iii.png",
    "duel_permit_iv" => "items/duel_permit_iv.png",
    "trading_license_i" => "items/trading_license_i.png",
    "trading_license_ii" => "items/trading_license_ii.png",
    "trading_license_iii" => "items/trading_license_iii.png",
    "doctor_license_i" => "items/doctor_license_i.png",
    "doctor_license_ii" => "items/doctor_license_ii.png",
    "doctor_license_iii" => "items/doctor_license_iii.png"
  }.freeze

  INVENTORY_CATEGORY_MARKS = {
    "all" => "All",
    "things" => "Gear",
    "elixirs" => "Elx",
    "fishing" => "Fish",
    "alchemy" => "Alch",
    "hunting" => "Hunt",
    "resources" => "Res",
    "wood" => "Wood",
    "quests" => "Quest"
  }.freeze

  # Family strip order observed in the live inventory capture. The source has no
  # "all" icon: its first family is the equipment family, so the local default
  # `all` category highlights the same cell.
  INVENTORY_FAMILY_STRIP = %w[things elixirs alchemy fishing hunting resources wood quests].freeze

  ITEM_DETAIL_LABELS = {
    "ap" => "Action Points",
    "action_points" => "Action Points",
    "armor_class" => "Armor class",
    "armor_pierce" => "Armor pierce",
    "armor_piercing" => "Armor pierce",
    "crushing" => "Crushing",
    "dexterity" => "Dexterity",
    "dodge" => "Dodge",
    "earth_resistance" => "Earth resistance",
    "evasion" => "Evasion",
    "fire_resistance" => "Fire resistance",
    "fortitude" => "Fortitude",
    "health" => "Health",
    "hp" => "HP",
    "intelligence" => "Knowledge",
    "knowledge" => "Knowledge",
    "luck" => "Luck",
    "mana" => "Mana",
    "mass" => "Mass",
    "max_hp" => "HP",
    "max_mp" => "Mana",
    "mp" => "Mana",
    "strength" => "Strength",
    "vitality" => "Health",
    "water_resistance" => "Water resistance",
    "air_resistance" => "Air resistance",
    "all_resistances" => "All elemental resistances",
    "two_handed" => "Two-handed",
    "two_handed_skill" => "Two-Handed Skill"
  }.freeze

  ITEM_SKILL_LABELS = {
    "unarmed_skill" => "Unarmed Combat",
    "unarmed_combat" => "Unarmed Combat",
    "sword_skill" => "Sword Skill",
    "sword_mastery" => "Sword Skill",
    "axe_skill" => "Axe Skill",
    "axe_mastery" => "Axe Skill",
    "blunt_skill" => "Bludgeoning Skill",
    "bludgeoning_skill" => "Bludgeoning Skill",
    "bludgeoning_mastery" => "Bludgeoning Skill",
    "knife_skill" => "Knife Skill",
    "knife_mastery" => "Knife Skill",
    "throwing_skill" => "Throwing Skill",
    "throwing_mastery" => "Throwing Skill",
    "polearm_skill" => "Polearm Skill",
    "polearm_mastery" => "Polearm Skill",
    "staff_skill" => "Staff Skill",
    "staff_mastery" => "Staff Skill",
    "two_handed_skill" => "Two-Handed Skill",
    "two_handed_mastery" => "Two-Handed Skill",
    "dual_wield_skill" => "Dual Wielding",
    "dual_wielding" => "Dual Wielding",
    "stealth" => "Stealth",
    "linguistics" => "Linguistics"
  }.freeze

  ITEM_EFFECT_SKIP_KEYS = %w[
    damage_min damage_max heal_hp restore_mp reset_allocation family weapon_family
  ].freeze

  def equipment_slot_icon(slot)
    SLOT_ICONS[slot.to_sym] || "[ ]"
  end

  def item_slot_icon(item_template)
    # Use item's icon if set, otherwise derive from type
    return item_template.icon if item_template.respond_to?(:icon) && item_template.icon.present?

    ITEM_TYPE_ICONS[item_template.item_type] || "IT"
  end

  def item_artwork_path(item_template)
    ITEM_ARTWORK_PATHS[item_template.key.to_s]
  end

  def inventory_category_options
    INVENTORY_CATEGORIES
  end

  def inventory_category_mark(category)
    INVENTORY_CATEGORY_MARKS.fetch(category.to_s, INVENTORY_CATEGORY_MARKS.fetch("all"))
  end

  def inventory_category_label(category)
    INVENTORY_CATEGORIES.to_h.fetch(category.to_s, category.to_s.humanize)
  end

  def inventory_things_subcategory_options
    THINGS_SUBCATEGORIES
  end

  def inventory_equipment_family?(category)
    category.to_s.in?(%w[all things])
  end

  def inventory_family_sections(category)
    FAMILY_SECTIONS.fetch(category.to_s, [])
  end

  def inventory_empty_message(category)
    FAMILY_EMPTY_STATES.fetch(category.to_s, "No items in this category.")
  end

  def inventory_requirement_rows(item)
    checker = Game::Inventory::RequirementChecker.new(character: current_character, item:)
    missing = checker.call.fetch(:missing, []).index_by { |entry| entry[:key].to_s }

    inventory_item_requirements(item).map do |label, value, requirement_key|
      normalized = requirement_key.presence || normalize_item_detail_key(label)
      missing_entry = missing[normalized]
      {
        label:,
        value: missing_entry ? "#{value} (current #{missing_entry[:current]})" : value,
        met: missing_entry.blank?
      }
    end
  end

  def inventory_item_action_allowed?(item)
    inventory_action_availability(item).fetch(:allowed)
  end

  def inventory_action_availability(item)
    Game::Inventory::RequirementChecker.call(character: current_character, item:)
  end

  def inventory_equipment_sets
    (@equipment_sets || {}).sort_by { |name, _payload| name.to_s.downcase }
  end

  def inventory_item_properties(item)
    template = item.item_template
    lines = []
    lines << ["Quantity", item.quantity] if item.quantity.to_i > 1
    lines << ["Price", "#{template.base_price} NV"] if template.base_price.to_i.positive?
    lines << ["Durability", inventory_item_durability(item)] if inventory_item_durability(item)
    lines << ["Damage", "#{template.stat_modifiers["damage_min"]}-#{template.stat_modifiers["damage_max"]}"] if template.stat_modifiers["damage_min"] && template.stat_modifiers["damage_max"]

    template.stat_modifiers.to_h.each do |stat, value|
      next if value.blank?
      next if ITEM_EFFECT_SKIP_KEYS.include?(normalize_item_detail_key(stat))

      append_inventory_property_rows(lines, stat, value)
    end

    template.display_properties.each do |label, value|
      append_inventory_property_rows(lines, label, value, signed: false)
    end

    item.properties.to_h.fetch("properties", {}).each do |label, value|
      append_inventory_property_rows(lines, label, value, signed: false)
    end

    lines << ["Description", template.description] if template.description.present?

    lines.presence || [["Description", template.item_type.to_s.titleize]]
  end

  def inventory_item_requirements(item)
    template = item.item_template
    requirements = template.requirements.to_h.merge(item.properties.to_h.fetch("requirements", {}))
    weight = item.weight.to_i.positive? ? item.weight : template.weight
    lines = [["Mass", weight, "mass"]]

    requirements.each do |label, value|
      append_inventory_requirement_rows(lines, label, value)
    end

    lines
  end

  def inventory_item_durability(item)
    current = item.properties["durability"] || item.properties["current_durability"]
    maximum = item.properties["max_durability"] || item.item_template.durability_max
    return nil if current.blank? && maximum.blank?
    return nil if current.to_i.zero? && maximum.to_i.zero?

    [current || maximum, maximum || current].join("/")
  end

  # Tooltip for a filled paper-doll slot.
  #
  # Mirrors the live `sl_alts` shape: item name first, then only the combat
  # values the source exposes on hover, then durability. Rendered as a plain
  # multi-line `title` so it stays available to keyboard and screen readers.
  def paperdoll_slot_tooltip(item, label)
    template = item.item_template
    modifiers = template.stat_modifiers.to_h
    lines = [template.name.presence || label]

    damage_min = modifiers["damage_min"].to_i
    damage_max = modifiers["damage_max"].to_i
    lines << "Damage: #{damage_min}-#{damage_max}" if damage_min.positive? || damage_max.positive?

    {"Armor class" => "armor_class", "Armor pierce" => "armor_pierce", "HP" => "max_hp", "Mana" => "max_mp"}
      .each do |title, key|
        amount = modifiers[key].to_i
        lines << "#{title}: #{signed_value(amount)}" unless amount.zero?
      end

    durability = inventory_item_durability(item)
    lines << "Durability: #{durability}" if durability

    lines.join("\n")
  end

  def inventory_item_durability_percent(item)
    current = (item.properties["durability"] || item.properties["current_durability"]).to_f
    maximum = (item.properties["max_durability"] || item.item_template.durability_max).to_f
    return 100 if maximum <= 0
    return 0 if current <= 0

    ((current / maximum) * 100).clamp(0, 100)
  end

  def signed_value(value)
    return value.to_json if value.is_a?(Hash) || value.is_a?(Array)

    numeric = value.to_i
    return value unless numeric.to_s == value.to_s

    numeric.positive? ? "+#{numeric}" : numeric.to_s
  end

  def append_inventory_property_rows(lines, label, value, signed: true, parent: nil)
    key = normalize_item_detail_key(label)

    if key == "skill_bonuses" && value.is_a?(Hash)
      value.each { |skill, amount| lines << [inventory_skill_label(skill), formatted_item_value(amount, signed:)] }
      return
    end

    if value.is_a?(Hash)
      value.each do |nested_label, nested_value|
        append_inventory_property_rows(lines, nested_label, nested_value, signed:, parent: label)
      end
      return
    end

    lines << [inventory_detail_label(label, parent:), formatted_item_value(value, signed:)]
  end

  def append_inventory_requirement_rows(lines, label, value, parent: nil)
    key = normalize_item_detail_key(label)
    return if %w[mass weight].include?(key)

    if value.is_a?(Hash)
      value.each do |nested_label, nested_value|
        append_inventory_requirement_rows(lines, nested_label, nested_value, parent: label)
      end
      return
    end

    lines << [inventory_detail_label(label, parent:), value, key]
  end

  def inventory_detail_label(label, parent: nil)
    key = normalize_item_detail_key(label)
    return inventory_skill_label(key) if ITEM_SKILL_LABELS.key?(key)

    base = ITEM_DETAIL_LABELS.fetch(key, key.titleize)
    parent_key = normalize_item_detail_key(parent)
    return base if parent.blank? || %w[stats skills requirements properties effects].include?(parent_key)

    "#{inventory_detail_label(parent)} #{base}"
  end

  def inventory_skill_label(skill)
    key = normalize_item_detail_key(skill)
    ITEM_SKILL_LABELS.fetch(key) do
      definition = Game::Skills::PassiveSkillRegistry.find(key)
      definition&.fetch(:name) || key.titleize
    end
  end

  def formatted_item_value(value, signed: true)
    return "yes" if value == true
    return "no" if value == false
    return value.to_json if value.is_a?(Array) || value.is_a?(Hash)
    return value unless signed

    signed_value(value)
  end

  def normalize_item_detail_key(key)
    key.to_s.strip.downcase.tr(" -", "_")
  end
end
