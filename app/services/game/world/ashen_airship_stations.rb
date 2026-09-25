# frozen_string_literal: true

module Game
  module World
    # Ensures Ashen airship station hotspots exist on catalog city nodes.
    # Safe to call on station entry / playable activation.
    class AshenAirshipStations
      STATIONS = [
        {"node_key" => "main", "key" => "airship_station", "name" => "Площадь Разломов"},
        {"node_key" => "forpost1", "key" => "airship_station", "name" => "Станция Разломов"},
        {"node_key" => "forpost2", "key" => "airship_station", "name" => "Маяк Разломов"},
        {"node_key" => "forpost3", "key" => "airship_station", "name" => "Пристань Разломов"},
        {"node_key" => "forpost4", "key" => "airship_station", "name" => "Цистерна Разломов"}
      ].freeze

      def self.ensure!
        new.call
      end

      def call
        STATIONS.each { |row| ensure_station!(row) }
      end

      private

      def ensure_station!(row)
        node = CityCatalog.node(row["node_key"])
        return unless node

        zone = Zone.find_by(name: node["zone_name"])
        return unless zone&.city?

        presentation = CityCatalog.hotspot_presentation(row["node_key"], row["key"]).to_h
        left, top, width, height = presentation.fetch("box", [0, 0, 120, 80])
        hotspot = CityHotspot.find_or_initialize_by(zone:, key: row["key"])
        hotspot.assign_attributes(
          name: row["name"],
          hotspot_type: "building",
          position_x: left,
          position_y: top,
          width:,
          height:,
          action_type: "open_feature",
          action_params: {"feature" => "airship_station"}.merge(presentation.slice("polygon")),
          required_level: 0,
          active: true,
          z_index: hotspot.z_index || 40
        )
        hotspot.save!
      end
    end
  end
end
