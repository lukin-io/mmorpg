# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TileBuildingService do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
  let(:source_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor") }
  let(:destination_zone) { create(:zone, name: "Форпост", location_type: "city") }
  let!(:building) do
    create(
      :tile_building,
      zone: source_zone.name,
      x: 3,
      y: 3,
      building_key: "outpost_gate",
      building_type: "city",
      name: "Ворота Форпоста",
      destination_zone: destination_zone,
      destination_x: 7,
      destination_y: 7,
      required_level: 5,
      active: true,
      metadata: {"description" => "Enter Форпост."}
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
        name: "Ворота Форпоста",
        building_type: "city",
        icon: "🏙️",
        destination: "Форпост",
        required_level: 5,
        description: "Enter Форпост.",
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
      expect(result.message).to include("Ворота Форпоста")
      expect(character.position.reload.zone).to eq(destination_zone)
      expect(character.position.x).to eq(7)
      expect(character.position.y).to eq(7)
    end

    it "returns a failure when the building is blocked" do
      building.update!(required_level: 20)

      result = service.enter!

      expect(result.success).to be false
      expect(result.message).to include("уровень 20")
      expect(character.position.reload.zone).to eq(source_zone)
    end
  end
end
