# frozen_string_literal: true

module Seeds
  # Creates only missing starter encounters from validated profile definitions.
  # Inputs are one zone's derived declarations and already persisted templates.
  # Existing placements are never rewritten; original-source provenance keeps a
  # moved or disabled bootstrap placement from being recreated at its old cell.
  # Reads are bounded to declared cells/source identities. No profession yields,
  # template stats, existing HP, or player position is changed by this bootstrap.
  # Returns placement IDs retained/created at declared cells for scoped cleanup.
  class StarterEncounterBootstrap
    SCOPE = "starter_encounter_bootstrap"
    POND_SOURCE_MAP = "m_1007_1002"

    def initialize(zone_name:, definitions:, templates:)
      @zone_name = zone_name
      @definitions = definitions
      @templates = templates
    end

    def call
      return [] if @definitions.empty?

      load_existing_content
      @definitions.each do |definition|
        coordinates = definition.values_at(:x, :y)
        source_map = definition.fetch(:metadata).fetch(:source_map)
        next if @occupied.include?(coordinates) || @bootstrapped_sources.include?(source_map)
        next unless eligible_cell?(@cells[coordinates], coordinates)

        @retained_ids << create_placement(definition, source_map).id
        @occupied.add(coordinates)
        @bootstrapped_sources.add(source_map)
      end
      @retained_ids
    end

    private

    def load_existing_content
      positions = {zone: @zone_name, x: @definitions.pluck(:x).uniq, y: @definitions.pluck(:y).uniq}
      @cells = MapTileTemplate.where(positions).index_by { |cell| [cell.x, cell.y] }
      existing = TileNpc.where(positions).pluck(:id, :x, :y)
      declared_coordinates = @definitions.map { |definition| definition.values_at(:x, :y) }.to_set
      existing.select! { |_id, x, y| declared_coordinates.include?([x, y]) }
      @retained_ids = existing.map(&:first)
      @occupied = existing.map { |_id, x, y| [x, y] }.to_set
      @entrances = TileBuilding.where(positions).pluck(:x, :y).to_set
      sources = @definitions.map { |definition| definition.fetch(:metadata).fetch(:source_map) }
      @bootstrapped_sources = TileNpc.where(zone: @zone_name)
        .where("metadata ->> 'seed_scope' = ?", SCOPE)
        .where("metadata ->> 'bootstrap_source_map' IN (?)", sources)
        .pluck(Arel.sql("metadata ->> 'bootstrap_source_map'")).to_set
    end

    def eligible_cell?(cell, coordinates)
      cell && !cell.blocked? && !@entrances.include?(coordinates) &&
        cell.metadata.to_h["source_map"] != POND_SOURCE_MAP && cell.metadata.dig("atlas", "id") != "8-326"
    end

    def create_placement(definition, source_map)
      metadata = definition.fetch(:metadata).deep_stringify_keys.merge(
        "seed_source" => "outdoor_npcs.yml", "seed_scope" => SCOPE, "bootstrap_source_map" => source_map
      )
      TileNpc.create!(
        zone: @zone_name, x: definition.fetch(:x), y: definition.fetch(:y),
        npc_template: @templates.fetch(definition.fetch(:key).to_s),
        npc_key: definition.fetch(:key).to_s, npc_role: definition.fetch(:role).to_s,
        level: definition.fetch(:level), max_hp: definition.fetch(:hp), current_hp: definition.fetch(:hp),
        metadata:
      )
    end
  end
end
