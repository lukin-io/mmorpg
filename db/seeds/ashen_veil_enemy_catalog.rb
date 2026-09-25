# frozen_string_literal: true

# Import Ashen Veil enemy catalog (99) into NpcTemplate.
# Catalog-only: does not place TileNpc rows or change combat UI.
return unless defined?(NpcTemplate)

path = Rails.root.join("config/gameplay/ashen_veil_enemy_catalog.json")
unless path.exist?
  warn "ashen_veil_enemy_catalog.json missing — skip enemy import"
  return
end

payload = JSON.parse(path.read)
entries = Array(payload["enemies"])
version = payload["catalog_version"].to_s

created = 0
updated = 0

entries.each do |raw|
  key = "av_#{raw.fetch("id")}"
  ru = raw.dig("name", "ru-RU").presence || raw.fetch("id")
  en = raw.dig("name", "en-US").presence || ru
  level = raw.fetch("level").to_i
  role_tag = raw["role"].presence || "normal"
  hp = raw.fetch("maxHp").to_i
  attack = raw.fetch("attack").to_i
  armor = raw.fetch("armor").to_i
  speed = raw.fetch("speed").to_i
  xp = raw.fetch("xp").to_i
  silver = raw["silver"].to_i
  magic = raw["magicPower"].to_i
  resist = raw["resist"].to_i

  name = ru
  if NpcTemplate.where.not(npc_key: key).exists?(name: name)
    name = "#{ru} [#{key}]"
  end

  template = NpcTemplate.find_or_initialize_by(npc_key: key)
  meta = template.metadata.to_h.merge(
    "health" => hp,
    "base_damage" => attack,
    "xp_reward" => xp,
    "armor" => armor,
    "speed" => speed,
    "magic_power" => magic,
    "resist" => resist,
    "silver" => silver,
    "seed_source" => "ashen_veil_enemy_catalog.json",
    "catalog_version" => version,
    "ashen_zone" => raw["zone"],
    "ashen_role" => role_tag,
    "english_name" => en,
    "source_name" => ru
  )

  template.assign_attributes(
    name: name,
    role: "hostile",
    level: level,
    dialogue: template.dialogue.presence || "...",
    metadata: meta
  )

  if template.new_record?
    template.save!
    created += 1
  elsif template.changed?
    template.save!
    updated += 1
  end
rescue StandardError => error
  warn "ashen enemy skip #{raw["id"]}: #{error.message}"
end

puts "Ashen Veil enemy catalog (#{version}): created=#{created} updated=#{updated} total_source=#{entries.size}"
