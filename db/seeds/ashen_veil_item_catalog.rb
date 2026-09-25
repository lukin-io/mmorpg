# frozen_string_literal: true

# Import Ashen Veil content catalog items (gap-closure-4920) into ItemTemplate.
# Source JSON is a one-shot export from packages/game-data ITEM_DEFINITIONS.
# Does not alter Neverlands UI; only upserts templates by stable key.
return unless defined?(ItemTemplate)

path = Rails.root.join("config/gameplay/ashen_veil_item_catalog.json")
unless path.exist?
  warn "ashen_veil_item_catalog.json missing — skip catalog import"
  return
end

payload = JSON.parse(path.read)
entries = Array(payload["items"])
version = payload["catalog_version"].to_s

SLOT_MAP = {
  "weapon" => "main_hand",
  "helm" => "head",
  "armor" => "chest",
  "gloves" => "hands",
  "bracers" => "bracers",
  "boots" => "feet",
  "amulet" => "amulet",
  "ring" => "ring",
  "earring" => "amulet",
  "relic" => "relic",
  "rune" => "none",
  "elixir" => "none",
  "scroll" => "none"
}.freeze

STAT_MAP = {
  "strength" => "strength",
  "agility" => "dexterity",
  "stamina" => "vitality",
  "intellect" => "intelligence",
  "will" => "will",
  "luck" => "luck",
  "attack" => "attack",
  "magicPower" => "magic_power",
  "armor" => "defense",
  "maxHp" => "hp",
  "speed" => "speed",
  "resist" => "resist",
  "maxMp" => "mp",
  "walkSpeed" => "walk_speed"
}.freeze

CONSUMABLE_SLOTS = %w[rune elixir scroll].freeze

def map_bonus(bonus)
  out = {}
  (bonus || {}).each do |key, value|
    mapped = STAT_MAP[key.to_s]
    next unless mapped
    next if value.nil? || value.to_i == 0

    out[mapped] = value.to_i
  end
  out
end

created = 0
updated = 0
entries.each do |raw|
  key = raw.fetch("id").to_s
  next if key.blank?

  ashen_slot = raw.fetch("slot").to_s
  nl_slot = SLOT_MAP.fetch(ashen_slot, "none")
  consumable = CONSUMABLE_SLOTS.include?(ashen_slot)
  item_type = consumable ? "consumable" : (nl_slot == "none" ? "misc" : "equipment")
  ru = raw.dig("name", "ru-RU").presence || raw.dig("name", "en-US").presence || key
  en = raw.dig("name", "en-US").presence || ru
  rarity = raw["rarity"].to_s
  stats = map_bonus(raw["bonus"])
  weight = [raw["weight"].to_i, 1].max
  durability = raw["isArtifact"] ? 0 : (consumable ? 1 : 100)

  item = ItemTemplate.find_or_initialize_by(key: key)
  # Keep unique name: on collision append key suffix.
  name = ru
  if ItemTemplate.where.not(id: item.id).exists?(name: name)
    name = "#{ru} [#{key}]"
  end

  rules = item.enhancement_rules.to_h.deep_dup
  rules["source_name"] = ru
  rules["english_name"] = en
  rules["ashen_veil"] = {
    "catalog_version" => version,
    "rarity" => rarity,
    "source_slot" => ashen_slot
  }
  rules["inventory_family"] ||= consumable ? "things" : "equipment"
  rules["subcategory"] ||= ashen_slot

  item.assign_attributes(
    name: name,
    item_type: item_type,
    slot: nl_slot,
    weight: weight,
    stack_limit: consumable ? 20 : 1,
    base_price: 0,
    durability_max: durability,
    requirements: item.requirements.to_h,
    stat_modifiers: item_type == "equipment" ? stats : (consumable ? stats : {}),
    enhancement_rules: rules
  )

  if item.new_record?
    item.save!
    created += 1
  elsif item.changed?
    item.save!
    updated += 1
  end
rescue StandardError => error
  warn "ashen catalog item skip #{raw["id"]}: #{error.message}"
end

puts "Ashen Veil item catalog (#{version}): created=#{created} updated=#{updated} total_source=#{entries.size}"
