# frozen_string_literal: true

# Activates Ashen Veil catalogs in runtime: shop tiers 1..23, stocks, NPC drop tables.
# Idempotent. Does not alter Neverlands combat button locks or login shell.
return unless defined?(ItemTemplate) && defined?(NpcTemplate)

SUBCATEGORY_MAP = {
  "weapon" => "swords",
  "helm" => "helmets",
  "armor" => "armor",
  "gloves" => "gloves",
  "bracers" => "bracers",
  "boots" => "boots",
  "amulet" => "jewelry",
  "ring" => "jewelry",
  "earring" => "jewelry",
  "relic" => "relics",
  "rune" => "runes",
  "scroll" => "scrolls",
  "elixir" => "misc"
}.freeze

shopped = 0
ItemTemplate.where("enhancement_rules -> 'ashen_veil' IS NOT NULL").find_each do |item|
  rules = item.enhancement_rules.to_h.deep_dup
  ashen = rules["ashen_veil"].to_h
  rarity = ashen["rarity"].presence || "common"
  source_slot = ashen["source_slot"].presence || "misc"
  tier = Game::Catalog::ShopTiering.tier_for(rarity)
  price = Game::Catalog::ShopTiering.price_for(rarity)
  subcategory = SUBCATEGORY_MAP.fetch(source_slot, "misc")

  rules["subcategory"] = subcategory
  rules["inventory_family"] ||= %w[rune elixir scroll].include?(source_slot) ? "things" : "equipment"
  rules["shop"] = Game::Catalog::ShopTiering.shop_entry(rarity:, position: shopped + 1)
  rules["shop_stock"] ||= {"current" => 40, "max" => 120}
  if key.start_with?("set-") && (match = key.match(/\Aset-(blood|demiurge|distortion|judge|swamp)-/))
    rules["set_key"] = "set-#{match[1]}"
    rules["set_name"] ||= match[1]
  end
  req = item.requirements.to_h.merge("level" => [tier, item.requirements.to_h["level"].to_i].max)

  item.assign_attributes(
    base_price: [item.base_price.to_i, price].max,
    requirements: req,
    enhancement_rules: rules
  )
  if item.changed?
    item.save!
    shopped += 1
  end
end

zone = Zone.find_by(name: Game::World::CityCatalog.node("main").fetch("zone_name")) rescue nil
shop = CityHotspot.find_by(zone:, key: "shop") if zone
if shop && defined?(ShopAccount)
  account = ShopAccount.find_by(location: shop)
  if account
    ApplicationRecord.transaction do
      account.lock!
      ItemTemplate.where("enhancement_rules -> 'ashen_veil' IS NOT NULL")
        .where("enhancement_rules @> ?", {shop: {sold: true}}.to_json)
        .find_each do |template|
        captured = template.shop_stock
        next unless captured.is_a?(Hash) && captured["current"].is_a?(Integer)

        account.shop_stocks.find_or_create_by!(item_template: template) do |stock|
          stock.current = captured.fetch("current")
          stock.maximum = captured["max"] || 120
        end
      end
    end
  end
end

# Build drop pools by tier from shopped catalog keys.
pools = Hash.new { |h, k| h[k] = [] }
ItemTemplate.where("enhancement_rules -> 'ashen_veil' IS NOT NULL").find_each do |item|
  tier = item.enhancement_rules.to_h.dig("shop", "tier").to_i
  tier = 1 if tier < 1
  pools[tier] << item.key
end

dropped = 0
NpcTemplate.where("npc_key LIKE 'av_%'").find_each do |npc|
  meta = npc.metadata.to_h.deep_dup
  level = npc.level.to_i.clamp(1, 23)
  candidates = (pools[level] + pools[[level - 1, 1].max] + pools[[level + 1, 23].min]).uniq
  next if candidates.empty?

  sample = candidates.sample([3, candidates.size].min)
  loot = sample.each_with_index.map do |key, idx|
    {
      "kind" => "item",
      "item_key" => key,
      "quantity" => 1,
      "chance" => [8, 12, 18][idx] || 10
    }
  end
  silver = meta["silver"].to_i
  if silver.positive?
    loot << {"kind" => "currency", "currency" => "NV", "amount" => [silver, 1].max, "chance" => 100}
  else
    loot << {"kind" => "currency", "currency" => "NV", "amount" => [level * 3, 1].max, "chance" => 70}
  end
  meta["loot_table"] = loot
  npc.update!(metadata: meta)
  dropped += 1
end

puts "Ashen Veil runtime activation: shop_updates=#{shopped} npc_loot=#{dropped} pools=#{pools.keys.size}"
