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

  FAMILY_EMPTY_KEYS = %w[elixirs quests all things].freeze

  FAMILY_SECTION_KEYS = {
    "alchemy" => [
      %w[alchemy_inventory alchemy_inventory_empty],
      %w[alchemy_resources alchemy_resources_empty]
    ],
    "fishing" => [
      %w[fishing_inventory fishing_inventory_empty],
      %w[alchemy_resources alchemy_resources_empty]
    ],
    "hunting" => [
      %w[cooking_inventory cooking_inventory_empty],
      %w[resources resources_empty]
    ],
    "resources" => [
      %w[resources resources_empty]
    ],
    "wood" => [
      %w[carpentry_inventory carpentry_inventory_empty],
      %w[resources resources_empty]
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

  # Family strip order observed in the live inventory capture. The source has no
  # "all" icon: its first family is the equipment family, so the local default
  # `all` category highlights the same cell.
  INVENTORY_FAMILY_STRIP = %w[things elixirs alchemy fishing hunting resources wood quests].freeze

  ITEM_DETAIL_I18N_KEYS = {
    "ap" => "action_points",
    "action_points" => "action_points",
    "armor_class" => "armor_class",
    "armor_pierce" => "armor_pierce",
    "armor_piercing" => "armor_pierce",
    "crushing" => "crushing",
    "dexterity" => "dexterity",
    "dodge" => "dodge",
    "earth_resistance" => "earth_resistance",
    "evasion" => "evasion",
    "fire_resistance" => "fire_resistance",
    "fortitude" => "fortitude",
    "health" => "health",
    "hp" => "hp",
    "intelligence" => "knowledge",
    "knowledge" => "knowledge",
    "luck" => "luck",
    "mana" => "mana",
    "mass" => "mass",
    "max_hp" => "hp",
    "max_mp" => "mana",
    "mp" => "mana",
    "strength" => "strength",
    "vitality" => "health",
    "water_resistance" => "water_resistance",
    "air_resistance" => "air_resistance",
    "all_resistances" => "all_resistances",
    "two_handed" => "two_handed",
    "two_handed_skill" => "two_handed_skill"
  }.freeze

  ITEM_SKILL_I18N_KEYS = {
    "unarmed_skill" => "unarmed_combat",
    "unarmed_combat" => "unarmed_combat",
    "sword_skill" => "sword_skill",
    "sword_mastery" => "sword_skill",
    "axe_skill" => "axe_skill",
    "axe_mastery" => "axe_skill",
    "blunt_skill" => "bludgeoning_skill",
    "bludgeoning_skill" => "bludgeoning_skill",
    "bludgeoning_mastery" => "bludgeoning_skill",
    "knife_skill" => "knife_skill",
    "knife_mastery" => "knife_skill",
    "throwing_skill" => "throwing_skill",
    "throwing_mastery" => "throwing_skill",
    "polearm_skill" => "polearm_skill",
    "polearm_mastery" => "polearm_skill",
    "staff_skill" => "staff_skill",
    "staff_mastery" => "staff_skill",
    "two_handed_skill" => "two_handed_skill",
    "two_handed_mastery" => "two_handed_skill",
    "dual_wield_skill" => "dual_wielding",
    "dual_wielding" => "dual_wielding",
    "stealth" => "stealth",
    "linguistics" => "linguistics"
  }.freeze

  ITEM_EFFECT_SKIP_KEYS = %w[
    damage_min damage_max heal_hp restore_mp reset_allocation family weapon_family
    buff buff_duration_seconds blood_tier
  ].freeze

  BUFF_MOD_LABELS = {
    "attack" => "Атака",
    "defense" => "Защита",
    "accuracy" => "Точность",
    "dodge" => "Уклон",
    "max_hp" => "Макс. HP",
    "gather_speed" => "Скорость сбора %",
    "fishing_skill" => "Рыбалка",
    "luck" => "Удача",
    "intelligence" => "Знания"
  }.freeze
  CRAFT_GEAR_PREFIXES = %w[ash_ranger_ ash_warden_ ash_battle_ ash_forager_].freeze

  def equipment_slot_icon(slot)
    SLOT_ICONS[slot.to_sym] || "[ ]"
  end

  def item_slot_icon(item_template)
    # Use item's icon if set, otherwise derive from type
    return item_template.icon if item_template.respond_to?(:icon) && item_template.icon.present?

    ITEM_TYPE_ICONS[item_template.item_type] || "IT"
  end

  def item_artwork_path(item_template, inventory_item: nil)
    custom = inventory_item&.properties.to_h["custom_icon"].presence
    return custom if custom.present?

    explicit = item_template.enhancement_rules.to_h["icon"].presence
    path = explicit.presence || ITEM_ARTWORK_PATHS[item_template.key.to_s]
    return if path.blank?

    path = path.to_s
    # Absolute CDN / public ashen paths stay absolute for image_tag.
    # Authored Propshaft assets under items/ must NOT get a leading slash, or
    # the browser requests /items/*.png outside the digested asset pipeline (404).
    return path if path.start_with?("http://", "https://", "/ashen/")

    path.delete_prefix("/")
  end

  def inventory_category_options
    INVENTORY_CATEGORIES.map { |key, _| [key, inventory_category_label(key)] }
  end

  def inventory_category_mark(category)
    I18n.t("game.inventory.marks.#{category}", default: I18n.t("game.inventory.marks.all"))
  end

  def inventory_category_label(category)
    I18n.t("game.inventory.categories.#{category}", default: category.to_s.tr("_", " "))
  end

  def inventory_things_subcategory_options
    THINGS_SUBCATEGORIES.map { |key, _| [key, I18n.t("game.inventory.subcategories.#{key}", default: key.to_s.tr("_", " "))] }
  end

  def inventory_equipment_family?(category)
    category.to_s.in?(%w[all things])
  end

  def inventory_family_sections(category)
    FAMILY_SECTION_KEYS.fetch(category.to_s, []).map do |title_key, empty_key|
      [I18n.t("game.inventory.sections.#{title_key}"), I18n.t("game.inventory.sections.#{empty_key}"), true]
    end
  end

  def inventory_empty_message(category)
    key = category.to_s
    if FAMILY_EMPTY_KEYS.include?(key)
      I18n.t("game.inventory.empty.#{key}")
    else
      I18n.t("game.common.no_items")
    end
  end

  def inventory_requirement_rows(item)
    checker = Game::Inventory::RequirementChecker.new(character: current_character, item:)
    missing = checker.call.fetch(:missing, []).index_by { |entry| entry[:key].to_s }

    inventory_item_requirements(item).map do |label, value, requirement_key|
      normalized = requirement_key.presence || normalize_item_detail_key(label)
      missing_entry = missing[normalized]
      {
        label:,
        value: missing_entry ? I18n.t("game.inventory.current_value", value:, current: missing_entry[:current]) : value,
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
    lines << [I18n.t("game.details.quantity"), item.quantity] if item.quantity.to_i > 1
    lines << [I18n.t("game.details.price"), "#{template.base_price} NV"] if template.base_price.to_i.positive?
    lines << [I18n.t("game.details.durability"), inventory_item_durability(item)] if inventory_item_durability(item)
    lines << [I18n.t("game.details.damage"), "#{template.stat_modifiers["damage_min"]}-#{template.stat_modifiers["damage_max"]}"] if template.stat_modifiers["damage_min"] && template.stat_modifiers["damage_max"]

    stats = template.stat_modifiers.to_h
    if stats["heal_hp"].present?
      lines << [I18n.t("game.details.heal_hp", default: "HP"), "+#{stats["heal_hp"].to_i}"]
    end
    if stats["restore_mp"].present?
      lines << [I18n.t("game.details.restore_mp", default: "MP"), "+#{stats["restore_mp"].to_i}"]
    end
    if stats["buff"].is_a?(Hash)
      blood = stats["blood_tier"].presence || template.enhancement_rules.to_h["blood_tier"]
      if blood.present?
        lines << [I18n.t("game.details.blood_tier", default: "Кровь"), Game::Professions::PotionCatalog.roman(blood)]
      end
      duration_min = (stats["buff_duration_seconds"].presence || 3600).to_i / 60
      lines << [I18n.t("game.details.buff_duration", default: "Длительность"), "#{duration_min} мин."]
      stats["buff"].each do |mod_key, value|
        label = BUFF_MOD_LABELS[mod_key.to_s] || mod_key.to_s
        signed = value.to_i.positive? ? "+#{value.to_i}" : value.to_i.to_s
        lines << [label, signed]
      end
    end

    stats.each do |stat, value|
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

    lines << [I18n.t("game.details.description"), template.description] if template.description.present?
    lines.concat(equipment_comparison_rows(template))

    lines.presence || [[I18n.t("game.details.description"), inventory_item_type_label(template.item_type)]]
  end

  def inventory_item_type_label(item_type)
    I18n.t("game.inventory.item_types.#{item_type}", default: item_type.to_s.tr("_", " "))
  end

  def inventory_item_requirements(item)
    template = item.item_template
    requirements = template.requirements.to_h.merge(item.properties.to_h.fetch("requirements", {}))
    weight = item.weight.to_i.positive? ? item.weight : template.weight
    lines = [[I18n.t("game.details.mass"), weight, "mass"]]

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
    lines << "#{I18n.t("game.details.damage")}: #{damage_min}-#{damage_max}" if damage_min.positive? || damage_max.positive?

    {
      I18n.t("game.details.armor_class") => %w[armor_class],
      I18n.t("game.details.armor_pierce") => %w[armor_pierce],
      I18n.t("game.details.hp") => %w[hp max_hp],
      I18n.t("game.details.mana") => %w[mana max_mp]
    }.each do |title, keys|
      amount = keys.sum { |key| modifiers[key].to_i }
      lines << "#{title}: #{signed_value(amount)}" unless amount.zero?
    end

    durability = inventory_item_durability(item)
    lines << "#{I18n.t("game.details.durability")}: #{durability}" if durability
    equipment_comparison_rows(template).each { |label, value| lines << "#{label}: #{value}" }

    lines.join("\n")
  end

  # Mist-War-style public hover: identity + requirements + durability, no raw
  # primary-stat dump (Ashen adaptation of the dense but quiet alt text).
  def mist_paperdoll_slot_tooltip(item, label)
    template = item.item_template
    lines = [template&.display_name.presence || template&.name.presence || label]
    lines << "#{I18n.t("game.dossier.equip_slot")}: #{label}"
    req = template&.requirements.to_h
    level = req["level"].to_i
    lines << "#{I18n.t("game.dossier.equip_req_level")}: #{level}" if level.positive?
    durability = inventory_item_durability(item)
    lines << "#{I18n.t("game.details.durability")}: #{durability}" if durability
    lines << I18n.t("game.dossier.equip_no_stats")
    lines.join("\n")
  end

  def equipment_comparison_rows(template)
    rules = template.enhancement_rules.to_h
    marked = CRAFT_GEAR_PREFIXES.any? { |prefix| template.key.to_s.start_with?(prefix) } ||
      rules["craft"].present? || rules["premium"].present? || rules["source"].to_s.in?(%w[craft premium])
    return [] unless marked && %w[equipment weapon armor accessory].include?(template.item_type.to_s)

    [
      [I18n.t("game.details.compare_shop", default: "Лавка"), I18n.t("game.details.compare_shop_value", default: "≈60% характеристик")],
      [I18n.t("game.details.compare_craft", default: "Крафт"), "#{template.base_price.to_i} NV · 100%"],
      [I18n.t("game.details.compare_premium", default: "Прем"), I18n.t("game.details.compare_premium_value", default: "выше крафта")]
    ]
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
    return inventory_skill_label(key) if ITEM_SKILL_I18N_KEYS.key?(key)

    i18n_key = ITEM_DETAIL_I18N_KEYS[key]
    base = i18n_key ? I18n.t("game.details.#{i18n_key}") : I18n.t("game.details.#{key}", default: key.tr("_", " "))
    parent_key = normalize_item_detail_key(parent)
    return base if parent.blank? || %w[stats skills requirements properties effects].include?(parent_key)

    "#{inventory_detail_label(parent)} #{base}"
  end

  def inventory_skill_label(skill)
    key = normalize_item_detail_key(skill)
    i18n_key = ITEM_SKILL_I18N_KEYS[key]
    return I18n.t("game.skills.#{i18n_key}") if i18n_key

    definition = Game::Skills::PassiveSkillRegistry.find(key)
    definition&.fetch(:name) || I18n.t("game.skills.#{key}", default: key.tr("_", " "))
  end

  def formatted_item_value(value, signed: true)
    return I18n.t("game.common.yes", default: "да") if value == true
    return I18n.t("game.common.no", default: "нет") if value == false
    return value.to_json if value.is_a?(Array) || value.is_a?(Hash)
    return value unless signed

    signed_value(value)
  end

  def normalize_item_detail_key(key)
    key.to_s.strip.downcase.tr(" -", "_")
  end
end
