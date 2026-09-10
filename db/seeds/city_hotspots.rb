# frozen_string_literal: true

forpost_city_zones = Seeds::WorldContentSupport.city_zones

# ============================================================
# CITY HOTSPOTS
# Captured actions for each city node
# ============================================================
puts "\n=== Seeding City Hotspots ==="

outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
city_zones_by_key = Game::World::CityCatalog::NODES.to_h do |node_key, node|
  [node_key, Zone.find_by(name: node["zone_name"])]
end
city_hotspots = []

Game::World::CityCatalog::NODES.each do |node_key, node|
  zone = city_zones_by_key[node_key]
  next unless zone

  node["links"].each do |destination_key, destination_name|
    presentation = Game::World::CityCatalog.hotspot_presentation(node_key, "go_#{destination_key}") || {}
    city_hotspots << {
      zone:,
      key: "go_#{destination_key}",
      name: destination_name,
      hotspot_type: "district",
      action_type: "enter_zone",
      destination_zone: city_zones_by_key[destination_key],
      action_params: {
        "destination_x" => 0,
        "destination_y" => 0,
        "direction" => presentation["direction"]
      }.compact,
      presentation:,
      required_level: 0
    }
  end

  node["features"].each do |feature_key, feature|
    presentation = Game::World::CityCatalog.hotspot_presentation(node_key, feature_key) || {}
    city_hotspots << {
      zone:,
      key: feature_key,
      name: feature["name"],
      hotspot_type: "building",
      action_type: "open_feature",
      destination_zone: nil,
      action_params: {"feature" => feature_key},
      presentation:,
      required_level: feature.fetch("required_level", 0)
    }
  end

  Game::World::CityCatalog::GATES.each do |gate_key, gate|
    next unless gate["node_key"] == node_key

    local_x, local_y = gate["local_coordinates"]
    city_hotspots << {
      zone:,
      key: "#{gate_key}_gate",
      name: gate["name"],
      hotspot_type: "exit",
      action_type: "enter_zone",
      destination_zone: outpost_surroundings,
      action_params: {
        "destination_x" => local_x,
        "destination_y" => local_y,
        "source_coordinates" => gate["source_coordinates"]
      },
      presentation: Game::World::CityCatalog.hotspot_presentation(node_key, "#{gate_key}_gate") || {},
      required_level: 0
    }
  end
end

seeded_hotspot_ids = city_hotspots.each_with_index.filter_map do |attrs, index|
  next unless attrs[:destination_zone] || attrs[:action_type] == "open_feature"

  left, top, width, height = attrs.fetch(:presentation, {}).fetch("box", [0, 0, nil, nil])
  hotspot = CityHotspot.find_or_initialize_by(zone: attrs[:zone], key: attrs[:key])
  hotspot.assign_attributes(
    name: attrs[:name],
    hotspot_type: attrs[:hotspot_type],
    position_x: left,
    position_y: top,
    width:,
    height:,
    image_normal: nil,
    image_hover: nil,
    action_type: attrs[:action_type],
    destination_zone: attrs[:destination_zone],
    action_params: (attrs[:action_params] || {}).merge(
      attrs.fetch(:presentation, {}).slice("polygon")
    ),
    required_level: attrs[:required_level] || 0,
    z_index: index,
    active: true
  )
  ApplicationRecord.transaction do
    Seeds::WorldContentSupport.cancel_changed_action_offers(hotspot)
    hotspot.save!
  end
  puts "  Created/Found CityHotspot: #{attrs[:name]}"
  hotspot.id
end

city_zone_ids = city_zones_by_key.values.compact.map(&:id)
forpost_city_zone_ids = forpost_city_zones.map(&:id)
retired_city_zone_ids = forpost_city_zone_ids - city_zone_ids
stale_hotspots = CityHotspot.where(zone_id: forpost_city_zone_ids).where.not(id: seeded_hotspot_ids)

ApplicationRecord.transaction do
  if defined?(WorldActionOffer)
    live_statuses = WorldActionOffer.statuses.values_at("offered", "accepted")
    WorldActionOffer.where(zone_id: retired_city_zone_ids, status: live_statuses).update_all(
      status: WorldActionOffer.statuses.fetch("cancelled"),
      error_message: "City layout was updated.",
      updated_at: Time.current
    )
  end

  Seeds::WorldContentSupport.retire_action_targets("CityHotspot", stale_hotspots)

  central_square = city_zones_by_key[Game::World::CityCatalog::STARTER_NODE_KEY]
  if defined?(CharacterPosition) && central_square && retired_city_zone_ids.any?
    CharacterPosition.where(zone_id: retired_city_zone_ids).find_each do |position|
      position.update!(zone: central_square, x: 0, y: 0)
    end
  end

  stale_hotspots.destroy_all
end

puts "City hotspots seeding complete!"
