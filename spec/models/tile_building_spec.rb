# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileBuilding, type: :model do
  let(:destination_zone) { create(:zone, name: "Castleton Keep", biome: "city") }
  let(:source_zone) { create(:zone, name: "Starter Plains", biome: "plains") }

  let(:valid_attributes) do
    {
      zone: source_zone.name,
      x: 5,
      y: 5,
      building_key: "test_castle_#{SecureRandom.hex(4)}",
      building_type: "castle",
      name: "Test Castle",
      destination_zone: destination_zone,
      required_level: 1,
      active: true
    }
  end

  describe "validations" do
    subject { described_class.new(valid_attributes) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires zone" do
      subject.zone = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:zone]).to include("can't be blank")
    end

    it "requires x coordinate" do
      subject.x = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:x]).to include("can't be blank")
    end

    it "requires y coordinate" do
      subject.y = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:y]).to include("can't be blank")
    end

    it "requires building_key" do
      subject.building_key = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:building_key]).to include("can't be blank")
    end

    it "requires unique building_key" do
      subject.save!
      duplicate = described_class.new(valid_attributes.merge(zone: "Other Zone", x: 10, y: 10))
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:building_key]).to include("has already been taken")
    end

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires valid building_type" do
      subject.building_type = "invalid_type"
      expect(subject).not_to be_valid
      expect(subject.errors[:building_type]).to include("is not included in the list")
    end

    it "accepts all valid building types" do
      TileBuilding::BUILDING_TYPES.each do |type|
        subject.building_type = type
        subject.building_key = "test_#{type}_#{SecureRandom.hex(4)}"
        expect(subject).to be_valid, "Expected #{type} to be valid"
      end
    end

    it "requires required_level to be at least 1" do
      subject.required_level = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:required_level]).to include("must be greater than or equal to 1")
    end

    it "requires non-negative coordinates" do
      subject.x = -1
      expect(subject).not_to be_valid

      subject.x = 5
      subject.y = -1
      expect(subject).not_to be_valid
    end
  end

  describe "associations" do
    subject { described_class.new(valid_attributes) }

    it "belongs to destination_zone (optional)" do
      expect(subject.destination_zone).to eq(destination_zone)

      subject.destination_zone = nil
      expect(subject).to be_valid
    end
  end

  describe "scopes" do
    let!(:active_building) do
      create(:tile_building, zone: source_zone.name, x: 1, y: 1, active: true)
    end

    let!(:inactive_building) do
      create(:tile_building, zone: source_zone.name, x: 2, y: 2, active: false)
    end

    let!(:other_zone_building) do
      create(:tile_building, zone: "Other Zone", x: 3, y: 3, active: true)
    end

    describe ".active" do
      it "returns only active buildings" do
        expect(described_class.active).to include(active_building)
        expect(described_class.active).not_to include(inactive_building)
      end
    end

    describe ".in_zone" do
      it "returns buildings in the specified zone" do
        expect(described_class.in_zone(source_zone.name)).to include(active_building)
        expect(described_class.in_zone(source_zone.name)).not_to include(other_zone_building)
      end
    end

    describe ".at_tile" do
      it "finds building at specific coordinates" do
        found = described_class.at_tile(source_zone.name, 1, 1)
        expect(found).to eq(active_building)
      end

      it "returns nil when no building exists" do
        found = described_class.at_tile(source_zone.name, 99, 99)
        expect(found).to be_nil
      end
    end

    describe ".by_type" do
      let!(:castle) do
        create(:tile_building, zone: source_zone.name, x: 10, y: 10, building_type: "castle")
      end

      let!(:inn) do
        create(:tile_building, zone: source_zone.name, x: 11, y: 11, building_type: "inn")
      end

      it "filters by building type" do
        expect(described_class.by_type("castle")).to include(castle)
        expect(described_class.by_type("castle")).not_to include(inn)
      end
    end
  end

  describe "#display_name" do
    subject { described_class.new(valid_attributes) }

    it "returns the name" do
      expect(subject.display_name).to eq("Test Castle")
    end

    it "falls back to titleized building_key when name is blank" do
      subject.name = ""
      subject.building_key = "my_castle_gate"
      expect(subject.display_name).to eq("My Castle Gate")
    end
  end

  describe "#display_icon" do
    subject { described_class.new(valid_attributes) }

    it "returns custom icon when set" do
      subject.icon = "🏯"
      expect(subject.display_icon).to eq("🏯")
    end

    it "returns default icon for building type when no custom icon" do
      subject.icon = nil
      subject.building_type = "inn"
      expect(subject.display_icon).to eq("🏨")
    end

    it "returns castle icon as final fallback" do
      subject.icon = nil
      subject.building_type = "unknown"
      expect(subject.display_icon).to eq("🏰")
    end
  end

  describe "#accessible?" do
    subject { described_class.new(valid_attributes) }

    it "returns true when active and has destination" do
      expect(subject).to be_accessible
    end

    it "returns false when inactive" do
      subject.active = false
      expect(subject).not_to be_accessible
    end

    it "returns false when no destination zone" do
      subject.destination_zone = nil
      expect(subject).not_to be_accessible
    end
  end

  describe "#can_enter?" do
    let(:character) { create(:character, level: 10) }
    let(:building) { create(:tile_building, destination_zone: destination_zone, required_level: 5, active: true) }

    it "returns true when character meets requirements" do
      expect(building.can_enter?(character)).to be true
    end

    it "returns false when building is inactive" do
      building.update!(active: false)
      expect(building.can_enter?(character)).to be false
    end

    it "returns false when character level is too low" do
      building.update!(required_level: 20)
      expect(building.can_enter?(character)).to be false
    end

    it "returns false when destination zone is missing" do
      building.update!(destination_zone: nil)
      expect(building.can_enter?(character)).to be false
    end
  end

  describe "#entry_blocked_reason" do
    let(:character) { create(:character, level: 5) }
    let(:building) { create(:tile_building, destination_zone: destination_zone, required_level: 10, active: true) }

    it "returns level requirement message when level is too low" do
      reason = building.entry_blocked_reason(character)
      expect(reason).to include("level 10")
    end

    it "returns nil when character can enter" do
      character.update!(level: 15)
      expect(building.entry_blocked_reason(character)).to be_nil
    end

    it "returns inaccessible message when inactive" do
      building.update!(active: false)
      expect(building.entry_blocked_reason(character)).to include("inaccessible")
    end
  end

  describe "#enter!" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user, level: 10) }
    let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 5, y: 5, default_entry: true) }
    let(:building) do
      create(
        :tile_building,
        zone: source_zone.name,
        destination_zone: destination_zone,
        destination_x: 7,
        destination_y: 7,
        required_level: 5,
        active: true
      )
    end

    before do
      character.create_position!(zone: source_zone, x: building.x, y: building.y, state: :active)
    end

    it "moves character to destination zone with specific coordinates" do
      expect(building.enter!(character)).to be true
      character.position.reload
      expect(character.position.zone).to eq(destination_zone)
      expect(character.position.x).to eq(7)
      expect(character.position.y).to eq(7)
    end

    it "uses spawn point when no specific coordinates given" do
      building.update!(destination_x: nil, destination_y: nil)
      expect(building.enter!(character)).to be true
      character.position.reload
      expect(character.position.x).to eq(spawn_point.x)
      expect(character.position.y).to eq(spawn_point.y)
    end

    it "returns false when character cannot enter" do
      building.update!(required_level: 20)
      expect(building.enter!(character)).to be false
      character.position.reload
      expect(character.position.zone).to eq(source_zone)
    end

    it "returns false when character has no position" do
      character.position.destroy
      character.reload
      expect(building.enter!(character)).to be false
    end
  end

  describe "#to_info_hash" do
    let(:building) do
      described_class.new(
        valid_attributes.merge(
          icon: "🏰",
          faction_key: "alliance",
          metadata: {"description" => "A grand castle"}
        )
      )
    end

    it "returns building info as hash" do
      hash = building.to_info_hash
      expect(hash[:name]).to eq("Test Castle")
      expect(hash[:building_type]).to eq("castle")
      expect(hash[:icon]).to eq("🏰")
      expect(hash[:destination]).to eq("Castleton Keep")
      expect(hash[:required_level]).to eq(1)
      expect(hash[:faction_key]).to eq("alliance")
      expect(hash[:description]).to eq("A grand castle")
    end
  end

  # ===========================================================================
  # Edge Cases and Null Value Tests
  # ===========================================================================
  describe "edge cases" do
    describe "coordinate boundaries" do
      subject { described_class.new(valid_attributes) }

      it "accepts zero coordinates" do
        subject.x = 0
        subject.y = 0
        expect(subject).to be_valid
      end

      it "accepts large coordinates" do
        subject.x = 9999
        subject.y = 9999
        expect(subject).to be_valid
      end
    end

    describe "metadata handling" do
      subject { described_class.new(valid_attributes) }

      it "handles nil metadata gracefully" do
        subject.metadata = nil
        # Nil metadata should still allow the model to be valid and not crash
        expect(subject).to be_valid
        expect(subject.metadata).to be_nil
      end

      it "handles empty metadata" do
        subject.metadata = {}
        expect(subject).to be_valid
      end

      it "handles complex nested metadata" do
        subject.metadata = {
          "description" => "Test",
          "required_quest" => "quest_key",
          "required_item" => "item_key",
          "nested" => {"key" => "value"}
        }
        expect(subject).to be_valid
      end
    end

    describe "quest requirement checking" do
      let(:character) { create(:character, level: 10) }
      let(:building) do
        create(
          :tile_building,
          destination_zone: destination_zone,
          required_level: 1,
          active: true,
          metadata: {"required_quest" => "test_quest"}
        )
      end

      context "when character has not completed required quest" do
        it "cannot enter building" do
          expect(building.can_enter?(character)).to be false
        end

        it "returns quest requirement reason" do
          reason = building.entry_blocked_reason(character)
          expect(reason).to include("requirements")
        end
      end

      context "when character has completed required quest" do
        before do
          quest = create(:quest, key: "test_quest")
          create(:quest_assignment, quest: quest, character: character, status: :completed)
        end

        it "can enter building" do
          expect(building.can_enter?(character)).to be true
        end
      end
    end

    describe "item requirement checking" do
      let(:user) { create(:user) }
      let(:character) { create(:character, user: user, level: 10) }
      let(:building) do
        create(
          :tile_building,
          zone: "Item Test Zone",
          x: 50,
          y: 50,
          building_key: "item_test_building",
          destination_zone: destination_zone,
          required_level: 1,
          active: true,
          metadata: {"required_item" => "test_key"}
        )
      end

      context "when character does not have required item" do
        it "cannot enter building" do
          expect(building.can_enter?(character)).to be false
        end
      end

      context "when character has required item" do
        before do
          item_template = create(:item_template, key: "test_key", name: "Test Item")
          character.inventory.inventory_items.create!(
            item_template: item_template,
            quantity: 1,
            weight: 1
          )
        end

        it "can enter building" do
          expect(building.can_enter?(character)).to be true
        end
      end
    end

    describe "multiple requirements" do
      let(:character) { create(:character, level: 5) }
      let(:building) do
        create(
          :tile_building,
          destination_zone: destination_zone,
          required_level: 10,
          active: true,
          metadata: {"required_quest" => "test_quest"}
        )
      end

      it "fails on first unmet requirement (level)" do
        reason = building.entry_blocked_reason(character)
        expect(reason).to include("level 10")
      end
    end

    describe "default spawn point fallback" do
      let(:user) { create(:user) }
      let(:character) { create(:character, user: user, level: 10) }
      let(:zone_without_spawn) { create(:zone, name: "No Spawn Zone", biome: "plains") }

      let(:building) do
        create(
          :tile_building,
          zone: source_zone.name,
          destination_zone: zone_without_spawn,
          destination_x: nil,
          destination_y: nil,
          required_level: 1,
          active: true
        )
      end

      before do
        character.create_position!(zone: source_zone, x: building.x, y: building.y, state: :active)
      end

      it "uses zone center as fallback when no spawn point exists" do
        building.enter!(character)
        character.position.reload
        # Should use center of zone (width/2, height/2)
        expect(character.position.x).to eq(zone_without_spawn.width / 2)
        expect(character.position.y).to eq(zone_without_spawn.height / 2)
      end
    end

    describe "BUILDING_ICONS constant" do
      it "has icons for all building types" do
        TileBuilding::BUILDING_TYPES.each do |type|
          expect(TileBuilding::BUILDING_ICONS).to have_key(type)
        end
      end
    end

    describe "icon fallback chain" do
      it "uses custom icon first" do
        building = described_class.new(valid_attributes.merge(icon: "🎭", building_type: "castle"))
        expect(building.display_icon).to eq("🎭")
      end

      it "uses type icon when no custom icon" do
        building = described_class.new(valid_attributes.merge(icon: nil, building_type: "inn"))
        expect(building.display_icon).to eq("🏨")
      end

      it "uses blank string icon" do
        building = described_class.new(valid_attributes.merge(icon: "", building_type: "inn"))
        expect(building.display_icon).to eq("🏨")
      end
    end

    describe "zone name with special characters" do
      it "handles zone names with spaces" do
        building = described_class.new(valid_attributes.merge(zone: "Starter Plains Area"))
        expect(building).to be_valid
      end

      it "handles zone names with apostrophes" do
        building = described_class.new(valid_attributes.merge(zone: "Dragon's Lair"))
        expect(building).to be_valid
      end
    end

    describe "concurrent access safety" do
      let(:user) { create(:user) }
      let(:character) { create(:character, user: user, level: 10) }
      let(:building) do
        create(
          :tile_building,
          zone: source_zone.name,
          destination_zone: destination_zone,
          required_level: 1,
          active: true
        )
      end

      before do
        character.create_position!(zone: source_zone, x: building.x, y: building.y, state: :active)
      end

      it "handles position update atomically" do
        expect {
          building.enter!(character)
        }.to change { character.position.reload.zone }.from(source_zone).to(destination_zone)
      end
    end
  end

  # ===========================================================================
  # Null Value Tests
  # ===========================================================================
  describe "null value handling" do
    subject { described_class.new(valid_attributes) }

    it "handles nil icon gracefully" do
      subject.icon = nil
      expect(subject.display_icon).to eq("🏰") # Falls back to type default
    end

    it "handles nil faction_key" do
      subject.faction_key = nil
      expect(subject).to be_valid
    end

    it "handles nil destination coordinates" do
      subject.destination_x = nil
      subject.destination_y = nil
      expect(subject).to be_valid
    end

    it "handles nil destination_zone" do
      subject.destination_zone = nil
      expect(subject).to be_valid
      expect(subject).not_to be_accessible
    end

    it "returns false for can_enter? with nil character" do
      building = create(:tile_building, destination_zone: destination_zone)
      expect { building.can_enter?(nil) }.to raise_error(NoMethodError)
    end
  end

  # ===========================================================================
  # Factory Tests
  # ===========================================================================
  describe "factory traits" do
    it "creates valid castle" do
      building = build(:tile_building, :castle)
      expect(building).to be_valid
      expect(building.building_type).to eq("castle")
    end

    it "creates valid inn" do
      building = build(:tile_building, :inn)
      expect(building).to be_valid
      expect(building.building_type).to eq("inn")
    end

    it "creates valid dungeon_entrance" do
      building = build(:tile_building, :dungeon_entrance)
      expect(building).to be_valid
      expect(building.building_type).to eq("dungeon_entrance")
    end

    it "creates valid portal" do
      building = build(:tile_building, :portal)
      expect(building).to be_valid
      expect(building.building_type).to eq("portal")
    end

    it "creates inactive building" do
      building = build(:tile_building, :inactive)
      expect(building.active).to be false
    end

    it "creates high level building" do
      building = build(:tile_building, :high_level)
      expect(building.required_level).to eq(50)
    end

    it "creates building with destination" do
      building = create(:tile_building, :with_destination)
      expect(building.destination_zone).to be_present
    end
  end
end
