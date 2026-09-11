# frozen_string_literal: true

forpost_city_zones = Seeds::WorldContentSupport.city_zones

if defined?(MapTileTemplate)
  # Neverlands cities are node graphs, not grid maps. Remove obsolete city
  # tiles instead of retaining a parallel generic-town representation.
  city_zone_names = forpost_city_zones.map(&:name)
  MapTileTemplate.where(zone: city_zone_names).delete_all

  # Outpost Surroundings uses sparse authored overrides inside one logical
  # 1000x1000 region. Missing in-bounds rows use the deterministic passable
  # outdoor default shared by rendering and movement validation. cell_art stores
  # only a stable catalog key and zero-based sheet location; passability,
  # entrances, local actions, and hidden NPCs remain independent layers.
  outpost_surroundings = Zone.find_by(name: "Outpost Surroundings")
  outdoor_tiles = outpost_surroundings ? Seeds::WorldContentSupport.outdoor_route_tiles(outpost_surroundings.name) : []

  outdoor_tiles.each do |attrs|
    next unless attrs[:zone]
    tile = MapTileTemplate.find_or_initialize_by(zone: attrs[:zone], x: attrs[:x], y: attrs[:y])
    source_map = tile.metadata.to_h["source_map"]
    next if tile.persisted? && source_map.present? &&
      !source_map.match?(/\Am_\d+_\d+\z/) && source_map != "forpost_pond_neighborhood_art"

    tile.terrain_type = attrs[:terrain_type]
    tile.passable = attrs.fetch(:passable, true) if tile.new_record?
    tile.metadata = attrs.fetch(:metadata, {}).merge(tile.metadata.to_h)
    tile.save!
  end

  # Bootstrap the bounded atlas survey into the same editable cell records.
  # Existing atlas-backed rows are operator-owned after import; reseeding must
  # not reopen a disabled cell or replace its managed actions/resources. Legacy
  # source/default-art rows receive the first survey, while unrelated authored
  # rows remain untouched. No NPC roster or successful yield is inferred here.
  if outpost_surroundings
    starter_catalog = Game::World::StarterCellCatalog.default
    starter_catalog.cells.each do |cell|
      tile = MapTileTemplate.find_or_initialize_by(zone: starter_catalog.zone_name, x: cell.x, y: cell.y)
      next if tile.metadata.to_h.key?("atlas")

      source_map = tile.metadata.to_h["source_map"]
      next if tile.persisted? && source_map.present? &&
        !source_map.match?(/\Am_\d+_\d+\z/) && source_map != "forpost_pond_neighborhood_art"

      tile.assign_attributes(Seeds::WorldContentSupport.starter_cell_attributes(cell, metadata: tile.metadata.to_h))
      tile.save!
    end
  end

  # One continuous 21x13 landscape replaces legacy terrain/pond art throughout
  # the bounded starter survey. Art coordinates are relative to local [0,2].
  # Existing independent artwork and already-managed starter references survive;
  # this visual upgrade never changes gameplay, labels or saved positions.
  if outpost_surroundings
    MapTileTemplate.where(zone: starter_catalog.zone_name, x: 0..20, y: 2..14).find_each do |tile|
      reference = tile.metadata.to_h["cell_art"]
      next unless reference.blank? || %w[forpost_terrain forpost_pond].include?(reference["key"])

      tile.update!(metadata: tile.metadata.to_h.merge(
        "cell_art" => Seeds::WorldContentSupport.starter_cell_art(tile.x, tile.y)
      ))
    end
  end

  if outpost_surroundings
    current_gate_cells = Game::World::CityCatalog::GATES.values.map { |gate| gate["local_coordinates"] }
    MapTileTemplate.where(zone: outpost_surroundings.name).find_each do |authored_tile|
      next unless authored_tile.metadata.to_h["city_gate"].present?
      next if current_gate_cells.include?([authored_tile.x, authored_tile.y])

      if starter_catalog.at(authored_tile.x, authored_tile.y)
        # Keep the surveyed cell: deleting it would restore sparse passable
        # terrain for a blocked coordinate until the next seed invocation.
        authored_tile.update!(metadata: authored_tile.metadata.except("city_gate"))
      else
        authored_tile.destroy!
      end
    end
  end
end
