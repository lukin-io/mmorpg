# frozen_string_literal: true

# Remap Neverlands item labels to Ashen Veil Russian names.
# Tiered thematic sets live in ashen_veil_thematic_sets.rb.
return unless defined?(ItemTemplate)

renamed = 0
ItemTemplate.find_each do |item|
  rules = item.enhancement_rules.to_h.deep_dup
  source = rules["source_name"].to_s.strip
  next if source.blank? || item.name == source

  rules["english_name"] ||= item.name
  item.update_columns(name: source, enhancement_rules: rules, updated_at: Time.current)
  renamed += 1
end
puts "Ashen item rename: #{renamed} templates"

material_names = {
  "wood_chips" => "Щепа Смолы",
  "rat_tail" => "Хвост Крысы Завесы",
  "ashen_bait" => "Приманка Завесы"
}
material_names.each do |key, name|
  item = ItemTemplate.find_by(key: key)
  next unless item && item.name != name

  rules = item.enhancement_rules.to_h.deep_dup
  rules["english_name"] ||= item.name
  rules["source_name"] = name
  item.update_columns(name: name, enhancement_rules: rules, updated_at: Time.current)
end

license_names = {
  "trading_license_i" => "Лицензия Торговца I",
  "trading_license_ii" => "Лицензия Торговца II",
  "trading_license_iii" => "Лицензия Торговца III",
  "doctor_license_i" => "Лицензия Лекаря I",
  "doctor_license_ii" => "Лицензия Лекаря II",
  "doctor_license_iii" => "Лицензия Лекаря III"
}
license_names.each do |key, name|
  item = ItemTemplate.find_by(key: key)
  next unless item && item.name != name

  rules = item.enhancement_rules.to_h.deep_dup
  rules["english_name"] ||= item.name
  rules["source_name"] = name
  item.update_columns(name: name, enhancement_rules: rules, updated_at: Time.current)
end

shop_hardcoded = {
  "knowledge_ring" => "Кольцо Знаний",
  "dexterity_ring" => "Кольцо Ловкости",
  "soul_hunter_pendant" => "Кулон Ловца Душ",
  "student_boots" => "Сапожки Ученика",
  "cowardly_gloves" => "Трусливые Перчатки",
  "north_wind_bracers" => "Наручи Северного Ветра",
  "damage_armor" => "Доспех Повреждений",
  "starwatcher_cap" => "Колпак Звездочёта",
  "reset_scroll" => "Свиток Обнуления",
  "imp_helper_summon" => "Призыв импа-помощника"
}
shop_hardcoded.each do |key, name|
  item = ItemTemplate.find_by(key: key)
  next unless item

  rules = item.enhancement_rules.to_h.deep_dup
  rules["english_name"] ||= item.name if item.name != name
  rules["source_name"] = name
  item.update_columns(name: name, enhancement_rules: rules, updated_at: Time.current)
end
