# frozen_string_literal: true

# Remap legacy Neverlands English zone labels to Ashen Veil (Пепельная Завеса).
# Uses update_columns to avoid validation/i18n side-effects during boot seed.

return unless defined?(Zone)

ZONE_RENAMES = {
  "Outpost" => "Город Под Пеплом",
  "Outpost Residential Quarter" => "Сгоревший Рынок",
  "Outpost Knowledge Quarter" => "Чёрный Маяк",
  "Outpost Business Quarter" => "Верфь Без Колоколов",
  "Outpost Law Quarter" => "Утонувшая Цистерна",
  "Пепельный Берег" => "Пепельный Берег"
}.freeze

ZONE_RENAMES.each do |from, to|
  zone = Zone.find_by(name: from)
  next unless zone
  next if Zone.exists?(name: to)

  zone.update_columns(name: to, updated_at: Time.current)
  puts "Renamed zone: #{from} -> #{to}"
end

if defined?(CityHotspot)
  HOTSPOT_RENAMES = {
    "Arena" => "Арена Пепла",
    "Shop" => "Лавка Смолы",
    "Hospital" => "Лазарет Угля",
    "Airship Station" => "Станция Разломов",
    "Market" => "Соляной Базар",
    "City Exit" => "Выход к Берегу",
    "Central Square" => "Площадь Угольных Огней",
    "Business Quarter" => "Верфь Без Колоколов",
    "Residential Quarter" => "Сгоревший Рынок",
    "Knowledge Quarter" => "Чёрный Маяк",
    "Law Quarter" => "Утонувшая Цистерна"
  }.freeze

  HOTSPOT_RENAMES.each do |from, to|
    CityHotspot.where(name: from).update_all(name: to, updated_at: Time.current)
  end
end
