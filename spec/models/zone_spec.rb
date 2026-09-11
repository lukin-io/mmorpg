# frozen_string_literal: true

require "rails_helper"

RSpec.describe Zone, type: :model do
  describe "region dimensions" do
    it "supports the single 1000 x 1000 MVP outdoor region" do
      region = build(:zone, :mvp_outdoor_region)

      expect(region).to be_valid
      expect(region).to have_attributes(location_type: "outdoor", width: 1000, height: 1000)
    end

    it "accepts the minimum positive boundary" do
      expect(build(:zone, :minimum_size)).to be_valid
    end

    it "rejects zero, negative, and null dimensions" do
      [
        build(:zone, width: 0),
        build(:zone, height: -1),
        build(:zone, width: nil)
      ].each do |region|
        expect(region).not_to be_valid
      end
    end
  end

  describe "location types" do
    it "distinguishes outdoor regions from cities" do
      expect(build(:zone, :mvp_outdoor_region)).to be_outdoor
      expect(build(:zone, :city)).to be_city
    end

    it "rejects a generic legacy location type" do
      region = build(:zone, location_type: "generic_location")

      expect(region).not_to be_valid
      expect(region.errors[:location_type]).to be_present
    end
  end

  describe "populated region identity" do
    let(:region) { create(:zone, :mvp_outdoor_region) }

    %i[map_tile_template tile_npc tile_building].each do |content_type|
      it "preserves the region name and content association for #{content_type}" do
        content = create(content_type, zone: region.name, x: 5, y: 5)
        original_name = region.name

        expect(region.update(name: "Renamed Region")).to be false
        expect(region.errors[:name]).to include("identifies populated region content; change the display title instead")
        expect(region.reload.name).to eq(original_name)
        expect(content.reload.zone).to eq(original_name)
        expect(Zone.find_by(name: original_name)).to eq(region)
      end

      it "prevents deletion from orphaning #{content_type}" do
        content = create(content_type, zone: region.name, x: 5, y: 5)

        expect(region.destroy).to be false
        expect(Zone.exists?(region.id)).to be true
        expect(content.reload.zone).to eq(region.reload.name)
      end
    end

    it "allows a display-title change while keeping content attached to its region" do
      tile = create(:map_tile_template, zone: region.name, x: 5, y: 5)

      region.update!(metadata: {"title" => "Displayed Region"})

      expect(region.display_name).to eq("Displayed Region")
      expect(region.map_tile_templates).to contain_exactly(tile)
      expect(Game::Movement::TileProvider.new(zone: region).tile_at(5, 5)).to be_present
    end

    it "permits renaming an empty region before content is authored" do
      expect(region.update(name: "Empty Authored Region")).to be true
    end
  end

  describe "city node identity" do
    it "accepts authored building silhouettes and rejects unsafe landmark polygon data" do
      zone = build(:zone, :city_node)
      zone.metadata["city_presentation"] = Game::World::CityCatalog.presentation("main").deep_dup
      expect(zone).to be_valid

      zone.metadata["city_presentation"]["landmarks"]["tavern"]["polygon"] = [[0, 0], [100, 0], [0, -1]]
      expect(zone).not_to be_valid
      expect(zone.errors[:metadata]).to include("city landmarks polygon must contain 3 to 32 percentage points enclosing an area")
    end

    it "exposes the stable node key and player-facing title" do
      node = build(:zone, :city_node)

      expect(node.city_node_key).to eq("main")
      expect(node.display_name).to eq("Central Square")
    end

    it "falls back to the zone name when city metadata is null or absent" do
      zone = build(:zone, name: "Fallback Zone", metadata: {})

      expect(zone.city_node_key).to be_nil
      expect(zone.display_name).to eq("Fallback Zone")
    end
  end

  describe "authored airship station title" do
    it "accepts an absent title and the 120-character boundary without replacing the zone identity" do
      zone = build(:zone, :city_node, name: "Stable Station Node")
      expect(zone).to be_valid
      expect(zone.airship_station_title).to be_nil

      zone.metadata["airship_station_title"] = "S" * 120
      expect(zone).to be_valid
      expect(zone.airship_station_title).to eq("S" * 120)
      expect(zone.display_name).to eq("Central Square")
      expect(zone.name).to eq("Stable Station Node")
    end

    it "rejects blank, non-string, and overlong authored labels and does not expose them for rendering" do
      [nil, "", "  ", 123, ["Station"], "S" * 121].each do |title|
        zone = build(:zone, :city, metadata: {"airship_station_title" => title})
        expect(zone).not_to be_valid
        expect(zone.errors[:metadata]).to include("airship_station_title must be a nonblank string of at most 120 characters")
        expect(zone.airship_station_title).to be_nil
      end
    end
  end
end
