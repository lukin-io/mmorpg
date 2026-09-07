# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileBuilding, type: :model do
  let(:source_zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:destination_zone) { create(:zone, name: "Outpost", location_type: "city") }
  let(:location_metadata) { build(:tile_building, :world_location).metadata }

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

    it "accepts an allowlisted open-world location entrance" do
      building.assign_attributes(
        building_type: "location",
        destination_zone: nil,
        destination_x: nil,
        destination_y: nil,
        metadata: location_metadata
      )

      expect(building).to be_valid
      expect(building).to be_accessible
      expect(building.location_features.pluck("key")).to contain_exactly("trading_post", "exit")
    end

    it "rejects an unconfigured or unsupported location definition" do
      building.assign_attributes(
        building_type: "location",
        destination_zone: nil,
        destination_x: nil,
        destination_y: nil,
        metadata: {}
      )

      expect(building).not_to be_valid
      expect(building).not_to be_accessible

      building.metadata = location_metadata.deep_merge(
        "location" => {
          "features" => [
            {
              "key" => "mine",
              "label" => "Mine",
              "action_type" => "open_feature",
              "feature" => "mine",
              "polygon" => [[1, 1], [4, 1], [2, 4]]
            }
          ]
        }
      )

      expect(building).not_to be_valid
      expect(building.errors[:metadata]).to include("location feature destination is unsupported")
    end

    it "rejects a location kind without an implemented source-backed interior" do
      location = build(:tile_building, :world_location)
      location.metadata.fetch("location")["kind"] = "mine"

      expect(location).not_to be_valid
      expect(location).not_to be_accessible
      expect(location.errors[:metadata]).to include("location kind is unsupported")
    end

    it "requires a documented building type" do
      building.building_type = "undocumented_service"

      expect(building).not_to be_valid
      expect(building.errors[:building_type]).to include("is not included in the list")
    end

    it "uses authored presence labels with the location name as an optional fallback" do
      location = build(:tile_building, :world_location)

      expect(location).to be_valid
      expect(location.location_presence_label).to eq("Village Square")
      expect(location.location_features.first.fetch("presence_label")).to eq("Shop")

      location.metadata.fetch("location").delete("presence_label")
      location.metadata.fetch("location").fetch("features").first.delete("presence_label")

      expect(location).to be_valid
      expect(location.location_presence_label).to eq(location.name)
    end

    it "validates an optional exterior presence label independently of entrance type" do
      building.metadata = {"presence_label" => "Outpost, West Gate"}
      expect(building).to be_valid
      expect(building.presence_label).to eq("Outpost, West Gate")

      building.metadata = {}
      expect(building).to be_valid
      expect(building.presence_label).to eq(building.name)

      [nil, "", " ", 3, []].each do |invalid_label|
        building.metadata = {"presence_label" => invalid_label}
        expect(building).not_to be_valid
        expect(building.errors[:metadata]).to include("presence label must be a non-empty string")
      end
    end

    it "rejects malformed authored room labels at the content boundary" do
      [nil, "", " ", 3, []].each do |invalid_label|
        location = build(:tile_building, :world_location)
        location.metadata.fetch("location")["presence_label"] = invalid_label
        location.metadata.fetch("location").fetch("features").first["presence_label"] = invalid_label

        expect(location).not_to be_valid
        expect(location.errors[:metadata]).to include(
          "location presence label must be a non-empty string",
          "location feature presence label must be a non-empty string"
        )
      end
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

    it "rejects an entrance at matching coordinates in a different region" do
      other_region = create(:zone, :mvp_outdoor_region)
      character.position.update!(zone: other_region)

      expect(building.can_enter?(character)).to be false
      expect(building.entry_blocked_reason(character)).to eq("Entrance is not on your current cell.")
      expect(building.enter!(character)).to be false
      expect(character.position.reload).to have_attributes(zone: other_region, x: building.x, y: building.y)
    end

    it "rechecks the saved source region when a cached character position has changed" do
      other_region = create(:zone, :mvp_outdoor_region)
      character.position
      CharacterPosition.find(character.position.id).update!(zone: other_region)

      expect(building.enter!(character)).to be false
      expect(character.position.reload.zone).to eq(other_region)
    end

    it "rechecks a cached entrance after its authored region changes" do
      other_region = create(:zone, :mvp_outdoor_region)
      TileBuilding.find(building.id).update!(zone: other_region.name)

      expect(building.enter!(character)).to be false
      expect(character.position.reload).to have_attributes(zone: source_zone, x: 5, y: 5)
    end

    it "rejects another cell in the same region and a repeated gate entry after arrival" do
      character.position.update!(x: 4)
      expect(building.enter!(character)).to be false
      expect(character.position.reload.zone).to eq(source_zone)

      character.position.update!(x: building.x)
      expect(building.enter!(character)).to be true
      arrival = character.position.reload.attributes.slice("zone_id", "x", "y", "last_action_at")

      expect(building.enter!(character)).to be false
      expect(character.position.reload.attributes.slice("zone_id", "x", "y", "last_action_at")).to eq(arrival)
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

    it "opens a location interior without replacing the persisted outdoor cell" do
      location = create(
        :tile_building,
        :world_location,
        zone: source_zone.name,
        x: 6,
        y: 7,
        building_key: "frontier_village"
      )
      character.position.update!(x: location.x, y: location.y)

      expect(location.enter!(character)).to be true
      expect(character.position.reload).to have_attributes(zone: source_zone, x: 6, y: 7)
    end
  end
end
