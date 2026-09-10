# frozen_string_literal: true

require_relative "world_content_support"

module Seeds
  # Repairs the two existing Forpost gate declarations and their bounded route
  # cells without running any other seed phase. #call returns changed-record
  # counts. It locks the three exact zones, preserves managed cells and unrelated
  # metadata, cancels changed targets' live capabilities, and commits both ends
  # together. Conflicting identities, occupied gate cells, or a managed blocked
  # route reject the transaction; characters and economy records are never read
  # or written. Normal seeds share the same content attribute builders.
  class ForpostGateRepair
    class Conflict < StandardError; end

    EASTERN_PATH = [[11, 9], [12, 10], [13, 10]].freeze

    def initialize(cell_catalog: Game::World::StarterCellCatalog.default)
      @cell_catalog = cell_catalog
    end

    def call
      @changes = {cells: 0, city_exits: 0, outdoor_entrances: 0, retired_markers: 0}
      ApplicationRecord.transaction do
        resolve_zones!
        repair_cells!
        verify_walkable_route!
        Game::World::CityCatalog::GATES.each do |key, gate|
          repair_gate!(key, gate)
        end
      end
      changes
    end

    private

    attr_reader :cell_catalog, :changes, :outdoors, :cities

    def resolve_zones!
      node_keys = Game::World::CityCatalog::GATES.values.pluck("node_key")
      names = node_keys.map { |key| Game::World::CityCatalog.node(key).fetch("zone_name") }
      rows = Zone.where(name: names + [cell_catalog.zone_name]).order(:id).lock.to_a
      @outdoors = exact_zone!(rows, cell_catalog.zone_name)
      reject!("Outdoor region identity does not match Forpost.") unless outdoors.outdoor? &&
        outdoors.metadata.to_h["source_map"] == "m_1001_999"
      @cities = node_keys.to_h do |key|
        city = exact_zone!(rows, Game::World::CityCatalog.node(key).fetch("zone_name"))
        reject!("City node identity does not match #{key}.") unless city.city? &&
          city.metadata.to_h["city_key"] == Game::World::CityCatalog::CITY_KEY && city.city_node_key == key
        duplicates = Zone.where(location_type: "city")
          .where("metadata ->> 'city_key' = ? AND metadata ->> 'city_node_key' = ?", Game::World::CityCatalog::CITY_KEY, key)
        reject!("Duplicate city node identity for #{key}.") unless duplicates.count == 1
        [key, city]
      end
    end

    def exact_zone!(rows, name)
      matches = rows.select { |zone| zone.name == name }
      reject!("Expected one zone named #{name}.") unless matches.one?
      matches.first
    end

    def route_coordinates
      @route_coordinates ||= (Game::World::CityCatalog::GATES.values.pluck("local_coordinates") + EASTERN_PATH).uniq
    end

    # Import immediate neighbors too: sparse missing cells are passable, so
    # repairing only the path would invent exits through source-blocked cells.
    def repair_cells!
      defaults = WorldContentSupport.outdoor_route_tiles(outdoors.name).index_by { |attrs| attrs.values_at(:x, :y) }
      coordinates = route_coordinates.flat_map do |x, y|
        (-1..1).to_a.product((-1..1).to_a).map { |dx, dy| [x + dx, y + dy] }
      end.uniq.sort
      coordinates.each do |x, y|
        cell = cell_catalog.at(x, y)
        reject!("Route cell is outside the captured starter catalog.") unless cell &&
          x.between?(0, outdoors.width - 1) && y.between?(0, outdoors.height - 1)
        tile = MapTileTemplate.lock.find_or_initialize_by(zone: outdoors.name, x:, y:)
        next if managed_cell?(tile)

        metadata = defaults.fetch([x, y], {}).fetch(:metadata, {}).merge(tile.metadata.to_h)
        tile.assign_attributes(WorldContentSupport.starter_cell_attributes(cell, metadata:))
        reference = tile.metadata["cell_art"]
        if reference.blank? || %w[forpost_terrain forpost_pond].include?(reference["key"])
          tile.metadata["cell_art"] = WorldContentSupport.starter_cell_art(x, y)
        end
        save_changed!(tile, :cells)
      end
    end

    def managed_cell?(tile)
      metadata = tile.metadata.to_h
      return true if metadata.key?("atlas")

      source = metadata["source_map"]
      tile.persisted? && source.present? && !source.match?(/\Am_\d+_\d+\z/) && source != "forpost_pond_neighborhood_art"
    end

    def verify_walkable_route!
      route_coordinates.each do |x, y|
        tile = MapTileTemplate.find_by!(zone: outdoors.name, x:, y:)
        reject!("Managed route cell [#{x},#{y}] is blocked; repair preserved it.") if tile.blocked?
      end
    end

    def repair_gate!(key, gate)
      city = cities.fetch(gate.fetch("node_key"))
      attributes = WorldContentSupport.gate_building_attributes(gate_key: key, gate:, city_zone: city, outdoors:)
      entrance = TileBuilding.lock.find_or_initialize_by(building_key: attributes.fetch(:building_key))
      reject!("Gate entrance belongs to another region or content type.") if entrance.persisted? &&
        (entrance.zone != outdoors.name || entrance.building_type != "city")
      occupant = TileBuilding.lock.find_by(zone: outdoors.name, x: attributes.fetch(:x), y: attributes.fetch(:y))
      reject!("Gate cell already contains an independently authored entrance.") if occupant && occupant != entrance
      previous_coordinates = [entrance.x, entrance.y] if entrance.persisted?
      entrance.assign_attributes(attributes.merge(active: true,
        metadata: entrance.metadata.to_h.merge(attributes.fetch(:metadata))))
      save_changed!(entrance, :outdoor_entrances)
      retire_previous_marker!(previous_coordinates, gate) if previous_coordinates && previous_coordinates != gate.fetch("local_coordinates")

      definition = WorldContentSupport.gate_hotspot_definition(gate_key: key, gate:, city_zone: city, outdoors:)
      hotspot = CityHotspot.lock.find_or_initialize_by(zone: city, key: definition.fetch(:key))
      reject!("City exit key belongs to a different action.") if hotspot.persisted? &&
        (hotspot.hotspot_type != "exit" || hotspot.action_type != "enter_zone")
      geometry = definition.fetch(:presentation)
      x, y, width, height = geometry.fetch("box")
      hotspot.assign_attributes(definition.except(:presentation, :action_params).merge(
        position_x: x, position_y: y, width:, height:, active: true,
        action_params: hotspot.action_params.to_h.except("direction", "polygon")
          .merge(definition.fetch(:action_params)).merge(geometry.slice("polygon"))
      ))
      save_changed!(hotspot, :city_exits)
    end

    def retire_previous_marker!(coordinates, gate)
      tile = MapTileTemplate.lock.find_by(zone: outdoors.name, x: coordinates.first, y: coordinates.last)
      return unless tile && tile.metadata.to_h["city_gate"] == gate.fetch("name")

      tile.metadata = tile.metadata.except("city_gate")
      save_changed!(tile, :retired_markers)
    end

    def save_changed!(record, kind)
      return unless record.new_record? || record.has_changes_to_save?

      WorldContentSupport.cancel_changed_action_offers(record)
      record.save!
      changes[kind] += 1
    end

    def reject!(message)
      raise Conflict, message
    end
  end
end
