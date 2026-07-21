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
      destination_x: 0,
      destination_y: 0,
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

    it "rejects speculative non-gate types" do
      %w[building special_location arena shop].each do |type|
        building.building_type = type

        expect(building).not_to be_valid
      end
    end
  end

  describe "scopes" do
    let!(:city_gate) { create(:tile_building, zone: source_zone.name, x: 1, y: 1, building_type: "city") }

    it "finds a building at a tile" do
      expect(described_class.at_tile(source_zone.name, 1, 1)).to eq(city_gate)
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

    it "does not apply removed generic level or item gates" do
      building.update!(
        required_level: 50,
        metadata: {"required_item" => "invented_gate_pass"}
      )

      expect(building.enter!(character)).to be true
      expect(character.position.reload.zone).to eq(destination_zone)
    end

    it "blocks an entrance without authored destination coordinates" do
      building.update_columns(destination_x: nil, destination_y: nil)

      expect(building.enter!(character)).to be false
      expect(character.position.reload.zone).to eq(source_zone)
    end

    it "blocks out-of-bounds destination coordinates" do
      building.update_columns(destination_x: destination_zone.width, destination_y: 0)

      expect(building.enter!(character)).to be false
      expect(character.position.reload.zone).to eq(source_zone)
    end

    it "blocks a null character" do
      expect(building.can_enter?(nil)).to be false
      expect(building.entry_blocked_reason(nil)).to eq("Character is unavailable.")
    end
  end
end
