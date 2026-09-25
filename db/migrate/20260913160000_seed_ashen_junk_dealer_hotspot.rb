# frozen_string_literal: true

# Upserts the Ashen junk dealer hotspot on the burned market node so buyback
# is reachable from the city map without a full city hotspot reseed.
class SeedAshenJunkDealerHotspot < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(Zone) && defined?(CityHotspot) && defined?(Game::World::CityCatalog)

    node = Game::World::CityCatalog::NODES.fetch("forpost1")
    zone = Zone.find_by(name: node.fetch("zone_name"))
    return unless zone

    landmark = Game::World::CityCatalog.presentation("forpost1").fetch("landmarks").fetch("junk_dealer")
    left, top, width, height = landmark.fetch("box")
    polygon = landmark["polygon"]

    hotspot = CityHotspot.find_or_initialize_by(zone:, key: "junk_dealer")
    hotspot.assign_attributes(
      name: landmark.fetch("name"),
      hotspot_type: "building",
      position_x: left,
      position_y: top,
      width:,
      height:,
      image_normal: nil,
      image_hover: nil,
      action_type: "open_feature",
      destination_zone: nil,
      action_params: {"feature" => "junk_dealer", "polygon" => polygon}.compact,
      required_level: 0,
      z_index: hotspot.z_index || 40,
      active: true
    )
    hotspot.save!
    say "seeded junk_dealer hotspot on #{zone.name}"
  end

  def down
    return unless defined?(Zone) && defined?(CityHotspot) && defined?(Game::World::CityCatalog)

    zone = Zone.find_by(name: Game::World::CityCatalog::NODES.fetch("forpost1").fetch("zone_name"))
    return unless zone

    CityHotspot.where(zone:, key: "junk_dealer").delete_all
  end
end
