# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TileBuildingService do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
  let(:source_zone) { create(:zone, name: "Starter Plains", biome: "plains") }
  let(:destination_zone) { create(:zone, name: "Starter City", biome: "city") }
  let!(:building) do
    create(
      :tile_building,
      zone: source_zone.name,
      x: 3,
      y: 3,
      building_key: "starter_city_gate",
      building_type: "city",
      name: "City Gates",
      destination_zone: destination_zone,
      destination_x: 7,
      destination_y: 7,
      required_level: 5,
      active: true,
      metadata: {"description" => "Enter the starter city node."}
    )
  end

  before do
    character.create_position!(zone: source_zone, x: 3, y: 3, state: :active)
  end

  describe "#building_info" do
    subject(:service) { described_class.new(character: character, zone: source_zone.name, x: 3, y: 3) }

    it "returns source-backed building display data" do
      expect(service.building_info).to include(
        id: building.id,
        name: "City Gates",
        building_type: "city",
        icon: "🏙️",
        destination: "Starter City",
        required_level: 5,
        description: "Enter the starter city node.",
        active: true
      )
    end

    it "returns nil when no building exists at the tile" do
      service = described_class.new(character: character, zone: source_zone.name, x: 99, y: 99)

      expect(service.building_info).to be_nil
    end

    it "hides inactive buildings" do
      building.update!(active: false)

      expect(service.building_info).to be_nil
    end
  end

  describe "#enter!" do
    subject(:service) { described_class.new(character: character, zone: source_zone.name, x: 3, y: 3) }

    it "moves the character into the destination zone" do
      result = service.enter!

      expect(result.success).to be true
      expect(result.message).to include("City Gates")
      expect(character.position.reload.zone).to eq(destination_zone)
      expect(character.position.x).to eq(7)
      expect(character.position.y).to eq(7)
    end

    it "returns a failure when the building is blocked" do
      building.update!(required_level: 20)

      result = service.enter!

      expect(result.success).to be false
      expect(result.message).to include("level 20")
      expect(character.position.reload.zone).to eq(source_zone)
    end
  end
end
