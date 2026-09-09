# frozen_string_literal: true

require "yaml"

module Game
  module World
    # Validates the bounded starter survey before seeds persist any cell facts.
    # .load reads trusted YAML; .new(data:) validates supplied data without IO.
    # #cells / #at(x, y) return immutable local coordinates, atlas passability
    # and evidence metadata. They do not write records or supply terrain, art,
    # actions, rewards, or combat rosters. NPC ranges are annotations only.
    # .default caches a validated catalog; .reload! retains it if loading fails.
    class StarterCellCatalog
      class InvalidConfigurationError < StandardError; end

      CONFIG_PATH = Rails.root.join("config/gameplay/starter_world_cells.yml")
      MAX_CELLS = 1000
      Cell = Data.define(:x, :y, :passable, :metadata)

      class << self
        def default
          @default ||= load
        end

        def reload!
          @default = load
        end

        def load(path: CONFIG_PATH)
          new(data: YAML.safe_load_file(path, aliases: false))
        rescue Psych::Exception, SystemCallError => error
          raise InvalidConfigurationError, "Starter cells could not be loaded: #{error.message}"
        end
      end

      attr_reader :zone_name, :cells

      def initialize(data:)
        validate_keys!(data, %w[zone_name source_origin source_bounds atlas_source cells], "catalog")
        @data = data.deep_dup
        validate_header!
        validate_cells!
        @zone_name = @data.fetch("zone_name").freeze
        @cells = @data.fetch("cells").map { |entry| build_cell(entry) }.freeze
        @by_position = cells.index_by { |cell| [cell.x, cell.y].freeze }.freeze
        @data = nil
        freeze
      end

      # Returns a surveyed cell or nil; unsurveyed positions have no facts here.
      def at(x, y)
        @by_position[[x, y]]
      end

      private

      def validate_header!
        validate_string!(@data.fetch("zone_name"), "zone_name", allow_empty: false)
        validate_pair!(@data.fetch("source_origin"), "source_origin")
        validate_keys!(@data.fetch("source_bounds"), %w[x y], "source_bounds")
        validate_bounds!
        validate_keys!(atlas_source, %w[url dataset_version captured_at coordinate_offset], "atlas_source")
        validate_pair!(atlas_source.fetch("coordinate_offset"), "atlas_source.coordinate_offset")
        %w[url dataset_version captured_at].each do |key|
          validate_string!(atlas_source.fetch(key), "atlas_source.#{key}", allow_empty: false)
        end
      end

      def validate_bounds!
        @ranges = %w[x y].each_with_index.map do |axis, index|
          bounds = @data.fetch("source_bounds").fetch(axis)
          validate_pair!(bounds, "source_bounds.#{axis}")
          origin = @data.fetch("source_origin").fetch(index)
          valid = bounds.first <= bounds.last && bounds.all? { |value| (0..999).cover?(value - origin) }
          invalid!("source_bounds.#{axis} must fit the local 1000-cell zone") unless valid
          bounds.first..bounds.last
        end
        @cell_count = @ranges.map(&:size).inject(:*)
        invalid!("source_bounds must contain at most #{MAX_CELLS} cells") if @cell_count > MAX_CELLS
      end

      def validate_cells!
        entries = @data.fetch("cells")
        unless entries.is_a?(Array) && entries.size == @cell_count
          invalid!("cells must contain all #{@cell_count} surveyed coordinates")
        end
        entries.each_with_index { |entry, index| validate_cell!(entry, "cells[#{index}]") }
        if entries.map { |entry| entry.fetch("source_coordinates") }.uniq.size != @cell_count
          invalid!("cells contain duplicate source coordinates")
        end
        if entries.map { |entry| entry.dig("atlas", "id") }.uniq.size != @cell_count
          invalid!("cells contain duplicate atlas IDs")
        end
      end

      def validate_cell!(entry, path)
        validate_keys!(entry, %w[source_coordinates atlas], path)
        source = entry.fetch("source_coordinates")
        validate_pair!(source, "#{path}.source_coordinates")
        unless source.each_with_index.all? { |value, index| @ranges.fetch(index).cover?(value) }
          invalid!("#{path}.source_coordinates are outside the surveyed bounds")
        end
        validate_atlas!(entry.fetch("atlas"), source, "#{path}.atlas")
      end

      def validate_atlas!(atlas, source, path)
        keys = %w[id coordinates label title kind active has_water has_fish herb_groups npc_annotations]
        validate_keys!(atlas, keys, path)
        unless atlas.fetch("id").is_a?(String) && atlas.fetch("id").match?(/\A[1-9]\d*-([1-9]\d*)\z/)
          invalid!("#{path}.id must be a segment-cell atlas identifier")
        end
        validate_pair!(atlas.fetch("coordinates"), "#{path}.coordinates")
        mapped = atlas.fetch("coordinates").zip(atlas_source.fetch("coordinate_offset")).map(&:sum)
        invalid!("#{path}.coordinates do not match source coordinates") unless mapped == source
        %w[label title kind].each { |key| validate_string!(atlas.fetch(key), "#{path}.#{key}") }
        %w[active has_water has_fish].each do |key|
          invalid!("#{path}.#{key} must be true or false") unless [true, false].include?(atlas.fetch(key))
        end
        validate_annotations!(atlas, path)
      end

      def validate_annotations!(atlas, path)
        groups = atlas.fetch("herb_groups")
        unless groups.is_a?(Array) && groups.size <= 32 && groups.uniq == groups &&
            groups.all? { |group| group.is_a?(Integer) && group.positive? }
          invalid!("#{path}.herb_groups must contain unique positive group IDs")
        end
        annotations = atlas.fetch("npc_annotations")
        unless annotations.is_a?(Array) && annotations.size <= 32
          invalid!("#{path}.npc_annotations must contain at most 32 annotations")
        end
        annotations.each_with_index { |entry, index| validate_npc!(entry, "#{path}.npc_annotations[#{index}]") }
      end

      def validate_npc!(entry, path)
        validate_keys!(entry, %w[name min_level max_level], path)
        validate_string!(entry.fetch("name"), "#{path}.name", allow_empty: false)
        levels = entry.values_at("min_level", "max_level")
        unless levels.all? { |level| level.is_a?(Integer) && (0..1000).cover?(level) } && levels.first <= levels.last
          invalid!("#{path} must have ordered integer levels within 0..1000")
        end
      end

      def build_cell(entry)
        source = entry.fetch("source_coordinates")
        x, y = source.zip(@data.fetch("source_origin")).map { |value, origin| value - origin }
        atlas = entry.fetch("atlas").merge("source" => atlas_source)
        metadata = {"source_map" => "m_#{source.join('_')}", "source_coordinates" => source, "atlas" => atlas}
        Cell.new(x:, y:, passable: atlas.fetch("active"), metadata: deep_freeze(metadata))
      end

      def atlas_source
        @data.fetch("atlas_source")
      end

      def validate_keys!(value, keys, path)
        return if value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) } && value.keys.sort == keys.sort

        invalid!("#{path} must contain exactly: #{keys.join(', ')}")
      end

      def validate_pair!(value, path)
        return if value.is_a?(Array) && value.size == 2 && value.all? { |number| number.is_a?(Integer) && number >= 0 }

        invalid!("#{path} must contain two nonnegative integers")
      end

      def validate_string!(value, path, allow_empty: true)
        return if value.is_a?(String) && value.length <= 240 && (allow_empty || value.present?)

        invalid!("#{path} must be a #{allow_empty ? '' : 'nonblank '}string of at most 240 characters")
      end

      def deep_freeze(value)
        case value
        when Hash then value.each { |key, item| deep_freeze(key); deep_freeze(item) }
        when Array then value.each { |item| deep_freeze(item) }
        end
        value.freeze
      end

      def invalid!(message)
        raise InvalidConfigurationError, "Starter cells #{message}"
      end
    end
  end
end
