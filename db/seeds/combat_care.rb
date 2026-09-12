# frozen_string_literal: true

# Captured hospital assortment and Doctor requirements; preserve traded stock.
goods = [
  ["beginner_healer_bag", "Beginner healer bag", "light", 300, 10, 20, 100, 33],
  ["skilled_healer_bag", "Skilled healer bag", "medium", 750, 10, 45, 300, 28],
  ["experienced_healer_bag", "Experienced healer bag", "heavy", 1500, 10, 90, 400, 143],
  ["combat_first_aid_kit", "Combat first-aid kit", "combat", 7000, 1, 160, 600, 1]
]
goods.each do |key, name, severity, price, uses, knowledge, doctor, _stock|
  template = ItemTemplate.find_or_initialize_by(key:)
  template.update!(name:, item_type: "misc", slot: "none", weight: 1,
    base_price: price, stack_limit: 1, durability_max: uses,
    stat_modifiers: {"heals_injury" => severity}, requirements: {"knowledge" => knowledge, "doctor" => doctor},
    enhancement_rules: {"inventory_family" => "things", "subcategory" => "aid_kits", "shop" => {"sold" => true}, "image" => "healer_bag.png"})
end
ItemTemplate.find_or_create_by!(key: "minor_health_potion") do |item|
  item.assign_attributes(name: "Small health elixir", item_type: "consumable", slot: "none", weight: 1,
    stack_limit: 10, stat_modifiers: {"heal_hp" => 50}, enhancement_rules: {"subcategory" => "potions"})
end
CityHotspot.where("action_params ->> 'feature' = ?", "hospital").find_each do |hospital|
  account = ShopAccount.find_or_create_by!(location: hospital) { |row| row.nv_balance = 0 }
  goods.each do |key, _name, _severity, _price, _uses, _knowledge, _doctor, count|
    account.shop_stocks.find_or_create_by!(item_template: ItemTemplate.find_by!(key:)) do |stock|
      stock.current = count
      stock.maximum = count
    end
  end
end
