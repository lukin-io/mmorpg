# frozen_string_literal: true

if defined?(Zone)
  city_zones = Game::World::CityCatalog::NODES.values.map do |node|
    {name: node["zone_name"], location_type: "city", width: 10, height: 10}
  end
  zones = city_zones + [
    {name: "Outpost Surroundings", location_type: "outdoor", width: 1000, height: 1000}
  ]

  zones.each do |attrs|
    zone = Zone.find_or_initialize_by(name: attrs[:name])
    zone.location_type = attrs[:location_type]
    zone.width = attrs[:width]
    zone.height = attrs[:height]
    zone.metadata = Seeds::WorldContentSupport.zone_metadata_for(attrs[:name])
    zone.save!
  end
end

forpost_city_zones = defined?(Zone) ? Seeds::WorldContentSupport.city_zones : []

if defined?(SpawnPoint) && defined?(Zone)
  city_zone_names = Game::World::CityCatalog::NODES.values.pluck("zone_name")
  central_square = Zone.find_by(
    name: Game::World::CityCatalog.node(Game::World::CityCatalog::STARTER_NODE_KEY)["zone_name"]
  )

  seeded_world_zones = Zone.where(name: city_zone_names + ["Outpost Surroundings"])
  SpawnPoint.where(zone: seeded_world_zones.or(Zone.where(id: forpost_city_zones.map(&:id)))).delete_all
  if central_square
    spawn = SpawnPoint.find_or_initialize_by(zone: central_square, x: 0, y: 0)
    spawn.assign_attributes(city_key: "forpost", default_entry: true)
    spawn.save!
  end
end
