# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::TileProvider do
  # This spec covers a bug where TileProvider couldn't find tiles because
  # MapTileTemplate.zone contained corrupted Zone object references
  # instead of zone name strings.
  #
  # Fix: MapTileTemplate.zone= setter converts Zone objects to names

  let(:zone) { create(:zone, name: "Outpost Surroundings") }

  before do
    # Create tiles with proper zone name strings
    create(:map_tile_template, zone: zone.name, x: 0, y: 0, terrain_type: "outdoor", passable: true)
    create(:map_tile_template, zone: zone.name, x: 1, y: 0, terrain_type: "outdoor", passable: true)
    create(:map_tile_template, zone: zone.name, x: 0, y: 1, terrain_type: "outdoor", passable: false)
  end

  describe "#tile_at" do
    subject(:provider) { described_class.new(zone: zone) }

    it "finds tiles by coordinates" do
      tile = provider.tile_at(0, 0)

      expect(tile).not_to be_nil
      expect(tile.x).to eq(0)
      expect(tile.y).to eq(0)
    end

    it "returns nil for non-existent tiles" do
      tile = provider.tile_at(99, 99)

      expect(tile).to be_nil
    end

    it "returns tile with correct passable status" do
      passable_tile = provider.tile_at(0, 0)
      impassable_tile = provider.tile_at(0, 1)

      expect(passable_tile.passable?).to be true
      expect(impassable_tile.passable?).to be false
    end

    context "with a sparse 1000 x 1000 outdoor region" do
      let(:zone) do
        create(
          :zone,
          name: "Neverlands Region",
          location_type: "outdoor",
          width: 1000,
          height: 1000
        )
      end

      it "treats an in-bounds cell without an authored row as passable" do
        tile = provider.tile_at(999, 999)

        expect(tile).to have_attributes(x: 999, y: 999)
        expect(tile).to be_passable
      end

      it "rejects coordinates beyond the region boundary" do
        expect(provider.tile_at(1000, 999)).to be_nil
        expect(provider.tile_at(999, 1000)).to be_nil
        expect(provider.tile_at(-1, 0)).to be_nil
      end
    end
  end

  describe "#terrain_type_at" do
    subject(:provider) { described_class.new(zone: zone) }

    it "returns explicit tile terrain type" do
      terrain_type = provider.terrain_type_at(0, 0)

      expect(terrain_type).to eq("outdoor")
    end

    it "returns nil for non-existent tiles" do
      terrain_type = provider.terrain_type_at(99, 99)

      expect(terrain_type).to be_nil
    end
  end

  describe "#metadata_at" do
    subject(:provider) { described_class.new(zone: zone) }

    before do
      create(
        :map_tile_template,
        zone: zone.name,
        x: 5,
        y: 5,
        terrain_type: "outdoor",
        metadata: {"source_map" => "m_1001_999"}
      )
    end

    it "returns tile metadata" do
      metadata = provider.metadata_at(5, 5)

      expect(metadata["source_map"]).to eq("m_1001_999")
    end

    it "returns empty hash for tiles without metadata" do
      metadata = provider.metadata_at(0, 0)

      expect(metadata).to eq({})
    end

    it "returns empty hash for non-existent tiles" do
      metadata = provider.metadata_at(99, 99)

      expect(metadata).to eq({})
    end
  end

  describe "bounded cell reads" do
    let(:zone) do
      create(:zone, name: "Sparse Region", location_type: "outdoor", width: 1000, height: 1000)
    end

    let(:tile_queries) { [] }
    let(:instantiated_tiles) { [] }

    def record_tile_reads
      query_subscriber = lambda do |event|
        sql = event.payload[:sql]
        tile_queries << sql if sql.match?(/\ASELECT .*FROM "map_tile_templates"/)
      end
      row_subscriber = lambda do |event|
        if event.payload[:class_name] == "MapTileTemplate"
          instantiated_tiles << event.payload[:record_count]
        end
      end

      ActiveRecord::Base.uncached do
        ActiveSupport::Notifications.subscribed(query_subscriber, "sql.active_record") do
          ActiveSupport::Notifications.subscribed(row_subscriber, "instantiation.active_record") do
            yield
          end
        end
      end
    end

    it "reads only requested exact cells and memoizes authored and sparse lookups" do
      create(:map_tile_template, zone: zone.name, x: 999, y: 999, passable: false)

      record_tile_reads do
        provider = described_class.new(zone:)
        expect(tile_queries).to be_empty

        expect(provider.tile_at(0, 0)).to be_passable
        expect(provider.metadata_at(0, 0)).to eq({})
        expect(provider.terrain_type_at(0, 0)).to eq("outdoor")
        expect(provider.tile_at(500, 500)).to be_passable
        expect(provider.metadata_at(500, 500)).to eq({})
        expect(provider.terrain_type_at(500, 500)).to be_nil
        expect(provider.tile_at(1000, 500)).to be_nil
        expect(provider.metadata_at(-1, 0)).to eq({})
        expect(provider.terrain_type_at(0, 1000)).to be_nil
      end

      expect(tile_queries.size).to eq(2)
      expect(instantiated_tiles.sum).to eq(1)
      expect(tile_queries).to all(include('"map_tile_templates"."zone" =', '"map_tile_templates"."x" =', '"map_tile_templates"."y" ='))
    end

    it "prefetches only the eight destination cells once, isolated from other regions" do
      coordinates = Game::Movement::Directions::OFFSETS.values.map { |dx, dy| [500 + dx, 500 + dy] }
      coordinates.each do |x, y|
        create(:map_tile_template, zone: zone.name, x:, y:, passable: true)
      end
      create(:map_tile_template, zone: zone.name, x: 500, y: 500, passable: false)
      create(:map_tile_template, zone: zone.name, x: 999, y: 999, passable: false)
      other_region = create(:zone, name: "Other Region", width: 1000, height: 1000)
      coordinates.each do |x, y|
        create(:map_tile_template, zone: other_region.name, x:, y:, passable: false)
      end

      record_tile_reads do
        provider = described_class.new(zone:, coordinates: coordinates + coordinates)
        coordinates.each do |x, y|
          expect(provider.tile_at(x, y)).to be_passable
          expect(provider.metadata_at(x, y)).to eq({})
          expect(provider.terrain_type_at(x, y)).to eq("outdoor")
        end
      end

      expect(tile_queries.size).to eq(1)
      expect(instantiated_tiles.sum).to eq(8)
    end

    it "memoizes sparse prefetched cells and skips coordinates outside region bounds" do
      coordinates = [[999, 998], [999, 999], [1000, 999], [-1, 0]]

      record_tile_reads do
        provider = described_class.new(zone:, coordinates:)
        expect(provider.tile_at(999, 998)).to be_passable
        expect(provider.metadata_at(999, 998)).to eq({})
        expect(provider.tile_at(999, 999)).to be_passable
        expect(provider.terrain_type_at(999, 999)).to be_nil
        expect(provider.tile_at(1000, 999)).to be_nil
        expect(provider.metadata_at(-1, 0)).to eq({})
      end

      expect(tile_queries.size).to eq(1)
      expect(instantiated_tiles.sum).to eq(0)
    end
  end
end
