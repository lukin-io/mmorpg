# frozen_string_literal: true

# Production outdoor zone "Пепельный Берег" had empty metadata (no source_map),
# so Seeds::ForpostGateRepair rejected identity. Gate MapTileTemplates existed
# at [6,8]/[11,9] but TileBuilding entrances were missing — players could exit
# the city and not re-enter. This migration upserts the two gate buildings and
# restores source_map without the strict Forpost repair precondition.
class RepairAshenForpostGateEntrances < ActiveRecord::Migration[8.1]
  def up
    outdoors = Zone.find_by(location_type: "outdoor", name: "Пепельный Берег")
    unless outdoors
      say "skip gate repair: outdoor zone missing"
      return
    end

    meta = outdoors.metadata.to_h
    if meta["source_map"].blank?
      outdoors.update!(metadata: meta.merge("source_map" => "m_1001_999"))
      say "restored outdoor source_map=m_1001_999"
    end

    Game::World::CityCatalog::GATES.each do |gate_key, gate|
      city_node_key = gate.fetch("node_key")
      city = Zone.where(location_type: "city").find do |zone|
        zone.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY &&
          zone.metadata.to_h["city_node_key"] == city_node_key
      end
      unless city
        say "skip #{gate_key}: city node #{city_node_key} missing"
        next
      end

      x, y = gate.fetch("local_coordinates")
      building_key = gate_key == "west" ? "outpost_gate" : "outpost_#{gate_key}_gate"
      building = TileBuilding.find_or_initialize_by(building_key: building_key)
      building.assign_attributes(
        zone: outdoors.name,
        x: x,
        y: y,
        building_type: "city",
        name: gate.fetch("name"),
        destination_zone: city,
        destination_x: 0,
        destination_y: 0,
        required_level: 0,
        active: true,
        metadata: building.metadata.to_h.merge(
          "description" => "Enter city through #{gate.fetch('name')}.",
          "presence_label" => gate.fetch("presence_label"),
          "source_map" => gate.fetch("source_map"),
          "source_coordinates" => gate.fetch("source_coordinates"),
          "source_gate" => gate_key,
          "city_node_key" => city_node_key,
          "seed_source" => "repair_ashen_forpost_gate_entrances"
        )
      )
      building.save!
      say "upserted #{building_key} at [#{x},#{y}] -> #{city.name}"
    end
  end

  def down
  end
end
