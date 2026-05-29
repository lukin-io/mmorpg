# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileBuilding, type: :model do
  let(:source_zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city") }

  let(:valid_attributes) do
    {
      zone: source_zone.name,
      x: 5,
      y: 5,
      building_key: "outpost_gate_#{SecureRandom.hex(4)}",
      building_type: "city",
      name: "Outpost Gate",
      destination_zone: destination_zone,
      required_level: 1,
      active: true
    }
  end

  describe "validations" do
    subject(:building) { described_class.new(valid_attributes) }

    it "is valid with a source-backed building type" do
      expect(building).to be_valid
    end

    it "requires a documented building type" do
      building.building_type = "undocumented_service"

      expect(building).not_to be_valid
      expect(building.errors[:building_type]).to include("is not included in the list")
    end

    it "accepts city, arena, and shop types" do
      described_class::BUILDING_TYPES.each do |type|
        building.building_type = type
        building.building_key = "#{type}_#{SecureRandom.hex(4)}"

        expect(building).to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:city_gate) { create(:tile_building, zone: source_zone.name, x: 1, y: 1, building_type: "city") }
    let!(:shop) { create(:tile_building, zone: source_zone.name, x: 2, y: 2, building_type: "shop") }

    it "finds a building at a tile" do
      expect(described_class.at_tile(source_zone.name, 1, 1)).to eq(city_gate)
    end

    it "filters by building type" do
      expect(described_class.by_type("city")).to include(city_gate)
      expect(described_class.by_type("city")).not_to include(shop)
    end
  end

  describe "#display_icon" do
    it "uses the documented type icon when no custom icon is set" do
      building = described_class.new(valid_attributes.merge(icon: nil, building_type: "arena"))

      expect(building.display_icon).to eq("⚔️")
    end

    it "falls back to the city icon" do
      building = described_class.new(valid_attributes.merge(icon: nil, building_type: "unknown"))

      expect(building.display_icon).to eq("🏙️")
    end
  end

  describe "#enter!" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user, level: 10) }
    let(:building) do
      create(
        :tile_building,
        valid_attributes.merge(destination_x: 7, destination_y: 8)
      )
    end

    before do
      character.create_position!(zone: source_zone, x: building.x, y: building.y, state: :active)
    end

    it "moves the character to the destination zone and coordinates" do
      expect(building.enter!(character)).to be true

      character.position.reload
      expect(character.position.zone).to eq(destination_zone)
      expect(character.position.x).to eq(7)
      expect(character.position.y).to eq(8)
    end

    it "blocks inactive buildings" do
      building.update!(active: false)

      expect(building.enter!(character)).to be false
    end
  end

  describe "#to_info_hash" do
    it "returns display data for the building action panel" do
      building = described_class.new(
        valid_attributes.merge(
          icon: "🚪",
          metadata: {"description" => "Enter Outpost."}
        )
      )

      expect(building.to_info_hash).to include(
        name: "Outpost Gate",
        building_type: "city",
        icon: "🚪",
        destination: "Outpost",
        description: "Enter Outpost."
      )
    end
  end
end
