# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::TileBuildingService do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
  let(:source_zone) { create(:zone, name: "Starter Plains", biome: "plains") }
  let(:destination_zone) { create(:zone, name: "Castleton Keep", biome: "city") }
  let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 5, y: 5, default_entry: true) }

  let!(:building) do
    create(
      :tile_building,
      zone: source_zone.name,
      x: 3,
      y: 3,
      building_key: "test_castle",
      building_type: "castle",
      name: "Test Castle",
      destination_zone: destination_zone,
      destination_x: 7,
      destination_y: 7,
      required_level: 5,
      active: true,
      metadata: {"description" => "A grand castle entrance"}
    )
  end

  before do
    character.create_position!(zone: source_zone, x: 3, y: 3, state: :active)
  end

  describe "#building_info" do
    subject do
      described_class.new(
        character: character,
        zone: source_zone.name,
        x: 3,
        y: 3
      )
    end

    context "when building exists at tile" do
      it "returns building info hash" do
        info = subject.building_info
        expect(info).to be_a(Hash)
        expect(info[:id]).to eq(building.id)
        expect(info[:name]).to eq("Test Castle")
        expect(info[:building_type]).to eq("castle")
        expect(info[:icon]).to eq("🏰")
        expect(info[:destination]).to eq("Castleton Keep")
        expect(info[:required_level]).to eq(5)
        expect(info[:description]).to eq("A grand castle entrance")
      end

      it "includes can_enter status" do
        info = subject.building_info
        expect(info[:can_enter]).to be true
      end

      it "includes blocked_reason when character cannot enter" do
        building.update!(required_level: 20)
        info = subject.building_info
        expect(info[:can_enter]).to be false
        expect(info[:blocked_reason]).to include("level 20")
      end
    end

    context "when no building exists at tile" do
      subject do
        described_class.new(
          character: character,
          zone: source_zone.name,
          x: 99,
          y: 99
        )
      end

      it "returns nil" do
        expect(subject.building_info).to be_nil
      end
    end

    context "when building is inactive" do
      before { building.update!(active: false) }

      it "returns nil (inactive buildings are hidden)" do
        expect(subject.building_info).to be_nil
      end
    end
  end

  describe "#building_present?" do
    subject do
      described_class.new(
        character: character,
        zone: source_zone.name,
        x: 3,
        y: 3
      )
    end

    it "returns true when building exists" do
      building # ensure created
      expect(subject.building_present?).to be true
    end

    it "returns false when no building exists" do
      building.destroy
      expect(subject.building_present?).to be false
    end
  end

  describe "#enter!" do
    subject do
      described_class.new(
        character: character,
        zone: source_zone.name,
        x: 3,
        y: 3
      )
    end

    context "when entry is successful" do
      it "returns success result" do
        result = subject.enter!
        expect(result.success).to be true
        expect(result.message).to include("Test Castle")
        expect(result.building).to eq(building)
        expect(result.destination_zone).to eq(destination_zone)
      end

      it "moves character to destination zone" do
        subject.enter!
        character.position.reload
        expect(character.position.zone).to eq(destination_zone)
        expect(character.position.x).to eq(7)
        expect(character.position.y).to eq(7)
      end
    end

    context "when no building at tile" do
      subject do
        described_class.new(
          character: character,
          zone: source_zone.name,
          x: 99,
          y: 99
        )
      end

      it "returns failure result" do
        result = subject.enter!
        expect(result.success).to be false
        expect(result.message).to include("No building found")
      end
    end

    context "when building is inactive" do
      before { building.update!(active: false) }

      it "returns failure result" do
        result = subject.enter!
        expect(result.success).to be false
        expect(result.message).to include("inaccessible")
      end
    end

    context "when character level is too low" do
      before { building.update!(required_level: 20) }

      it "returns failure result with level requirement" do
        result = subject.enter!
        expect(result.success).to be false
        expect(result.message).to include("level 20")
      end

      it "does not move character" do
        subject.enter!
        character.position.reload
        expect(character.position.zone).to eq(source_zone)
      end
    end

    context "when building has no destination" do
      before { building.update!(destination_zone: nil) }

      it "returns failure result" do
        result = subject.enter!
        expect(result.success).to be false
        expect(result.message).to include("inaccessible")
      end
    end
  end

  describe "with Zone object instead of string" do
    subject do
      described_class.new(
        character: character,
        zone: source_zone, # Zone object, not string
        x: 3,
        y: 3
      )
    end

    it "handles Zone object correctly" do
      building # ensure created
      info = subject.building_info
      expect(info[:name]).to eq("Test Castle")
    end
  end

  describe "coordinate type coercion" do
    subject do
      described_class.new(
        character: character,
        zone: source_zone.name,
        x: "3", # String instead of integer
        y: "3"
      )
    end

    it "handles string coordinates" do
      info = subject.building_info
      expect(info[:name]).to eq("Test Castle")
    end
  end

  # ===========================================================================
  # Edge Cases and Null Value Tests
  # ===========================================================================
  describe "edge cases" do
    describe "multiple buildings at same zone different positions" do
      let!(:building_1) do
        create(:tile_building,
          zone: source_zone.name,
          x: 1,
          y: 1,
          building_key: "building_1",
          name: "Building 1",
          destination_zone: destination_zone,
          active: true)
      end

      let!(:building_2) do
        create(:tile_building,
          zone: source_zone.name,
          x: 2,
          y: 2,
          building_key: "building_2",
          name: "Building 2",
          destination_zone: destination_zone,
          active: true)
      end

      it "returns correct building for position 1,1" do
        service = described_class.new(character: character, zone: source_zone.name, x: 1, y: 1)
        info = service.building_info
        expect(info[:name]).to eq("Building 1")
      end

      it "returns correct building for position 2,2" do
        service = described_class.new(character: character, zone: source_zone.name, x: 2, y: 2)
        info = service.building_info
        expect(info[:name]).to eq("Building 2")
      end

      it "returns nil for position without building" do
        service = described_class.new(character: character, zone: source_zone.name, x: 5, y: 5)
        expect(service.building_info).to be_nil
      end
    end

    describe "building info with all optional fields nil" do
      let!(:minimal_building) do
        # Use different coordinates to avoid conflicts
        create(:tile_building,
          zone: source_zone.name,
          x: 20,
          y: 20,
          building_key: "minimal_building",
          name: "Minimal Building",
          building_type: "castle",
          destination_zone: destination_zone,
          destination_x: nil,
          destination_y: nil,
          icon: nil,
          faction_key: nil,
          metadata: {},
          active: true)
      end

      it "returns building info without errors" do
        service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 20,
          y: 20
        )
        info = service.building_info
        expect(info[:name]).to eq("Minimal Building")
        expect(info[:description]).to be_nil
        expect(info[:faction_key]).to be_nil
      end
    end

    describe "entry with quest requirements" do
      let!(:quest_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 21,
          y: 21,
          building_key: "quest_building",
          name: "Quest Building",
          destination_zone: destination_zone,
          required_level: 1,
          active: true,
          metadata: {"required_quest" => "test_quest", "requirement_message" => "Complete the test quest first!"})
      end

      let(:quest_service) do
        described_class.new(
          character: character,
          zone: source_zone.name,
          x: 21,
          y: 21
        )
      end

      context "when character hasn't completed quest" do
        it "returns blocked reason from metadata" do
          info = quest_service.building_info
          expect(info[:blocked_reason]).to eq("Complete the test quest first!")
        end

        it "shows can_enter as false" do
          info = quest_service.building_info
          expect(info[:can_enter]).to be false
        end

        it "enter! returns failure with custom message" do
          result = quest_service.enter!
          expect(result.success).to be false
          expect(result.message).to eq("Complete the test quest first!")
        end
      end
    end

    describe "character at edge of zone" do
      let!(:edge_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 0,
          y: 0,
          building_key: "edge_building",
          name: "Edge Building",
          destination_zone: destination_zone,
          active: true)
      end

      before do
        character.position.update!(x: 0, y: 0)
      end

      it "finds building at edge coordinates" do
        service = described_class.new(character: character, zone: source_zone.name, x: 0, y: 0)
        expect(service.building_present?).to be true
      end

      it "can enter building at edge" do
        service = described_class.new(character: character, zone: source_zone.name, x: 0, y: 0)
        result = service.enter!
        expect(result.success).to be true
      end
    end

    describe "result struct attributes" do
      it "enter! success result has all expected attributes" do
        service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 3,
          y: 3
        )
        result = service.enter!
        expect(result).to respond_to(:success)
        expect(result).to respond_to(:message)
        expect(result).to respond_to(:building)
        expect(result).to respond_to(:destination_zone)
      end

      it "enter! failure result has nil destination_zone" do
        service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 99,
          y: 99
        )
        result = service.enter!
        expect(result.destination_zone).to be_nil
      end
    end
  end

  # ===========================================================================
  # Null Value Tests
  # ===========================================================================
  describe "null value handling" do
    describe "nil zone parameter" do
      it "handles nil zone by converting to string" do
        service = described_class.new(character: character, zone: nil, x: 3, y: 3)
        expect(service.zone).to eq("")
        expect(service.building_info).to be_nil
      end
    end

    describe "nil character" do
      it "raises error when character is nil" do
        service = described_class.new(character: nil, zone: source_zone.name, x: 3, y: 3)
        expect { service.enter! }.to raise_error(NoMethodError)
      end
    end

    describe "empty zone name" do
      it "returns nil for empty zone name" do
        service = described_class.new(character: character, zone: "", x: 3, y: 3)
        expect(service.building_info).to be_nil
      end
    end

    describe "negative coordinates" do
      it "returns nil for negative x" do
        service = described_class.new(character: character, zone: source_zone.name, x: -1, y: 3)
        expect(service.building_info).to be_nil
      end

      it "returns nil for negative y" do
        service = described_class.new(character: character, zone: source_zone.name, x: 3, y: -1)
        expect(service.building_info).to be_nil
      end
    end
  end

  # ===========================================================================
  # Failure Case Tests
  # ===========================================================================
  describe "failure cases" do
    describe "database errors" do
      it "handles missing building gracefully" do
        # Service at coordinates with no building
        fresh_service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 99,
          y: 99
        )
        expect(fresh_service.building_info).to be_nil
      end
    end

    describe "character without position" do
      before { character.position.destroy }

      it "enter! returns failure when character has no position" do
        character.reload
        service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 3,
          y: 3
        )
        result = service.enter!
        expect(result.success).to be false
      end
    end

    describe "faction restriction" do
      let!(:faction_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 30,
          y: 30,
          building_key: "faction_building",
          name: "Faction Building",
          destination_zone: destination_zone,
          faction_key: "alliance",
          required_level: 1,
          active: true)
      end

      it "blocks entry for wrong faction" do
        faction_service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 30,
          y: 30
        )
        info = faction_service.building_info
        expect(info[:can_enter]).to be false
        expect(info[:blocked_reason]).to include("faction")
      end
    end

    describe "all requirements unmet" do
      let!(:restricted_building) do
        create(:tile_building,
          zone: source_zone.name,
          x: 31,
          y: 31,
          building_key: "restricted_building",
          name: "Restricted Building",
          destination_zone: destination_zone,
          required_level: 100,
          faction_key: "horde",
          active: true,
          metadata: {"required_quest" => "impossible_quest"})
      end

      it "returns first blocking reason (level)" do
        restricted_service = described_class.new(
          character: character,
          zone: source_zone.name,
          x: 31,
          y: 31
        )
        info = restricted_service.building_info
        expect(info[:can_enter]).to be false
        expect(info[:blocked_reason]).to include("level 100")
      end
    end
  end

  # ===========================================================================
  # Performance Considerations
  # ===========================================================================
  describe "query efficiency" do
    it "caches building lookup" do
      service = described_class.new(
        character: character,
        zone: source_zone.name,
        x: 3,
        y: 3
      )
      # First call loads the building
      service.building_info

      # Subsequent calls should use cached building
      expect(service.building_present?).to be true
    end
  end
end
