# frozen_string_literal: true

require "rails_helper"

RSpec.describe CityHotspot, type: :model do
  let(:city_zone) { create(:zone, name: "Test City", biome: "city") }
  let(:destination_zone) { create(:zone, name: "Destination Zone", biome: "plains") }

  let(:valid_attributes) do
    {
      zone: city_zone,
      key: "test_building",
      name: "Test Building",
      hotspot_type: "building",
      position_x: 100,
      position_y: 200,
      image_normal: "building.png",
      action_type: "open_feature",
      action_params: {"feature" => "test"},
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
    end

    it "requires key" do
      subject.key = nil
      expect(subject).not_to be_valid
    end

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it "requires hotspot_type" do
      subject.hotspot_type = nil
      expect(subject).not_to be_valid
    end

    it "requires valid hotspot_type" do
      subject.hotspot_type = "invalid"
      expect(subject).not_to be_valid
    end

    it "requires action_type" do
      subject.action_type = nil
      expect(subject).not_to be_valid
    end

    it "requires valid action_type" do
      subject.action_type = "invalid"
      expect(subject).not_to be_valid
    end

    it "requires position_x" do
      subject.position_x = nil
      expect(subject).not_to be_valid
    end

    it "requires position_y" do
      subject.position_y = nil
      expect(subject).not_to be_valid
    end

    it "requires non-negative position_x" do
      subject.position_x = -1
      expect(subject).not_to be_valid
    end

    it "requires non-negative position_y" do
      subject.position_y = -1
      expect(subject).not_to be_valid
    end

    it "requires unique key per zone" do
      create(:city_hotspot, zone: city_zone, key: "unique_key")
      subject.key = "unique_key"
      expect(subject).not_to be_valid
    end

    it "allows same key in different zones" do
      other_zone = create(:zone, name: "Other Zone")
      create(:city_hotspot, zone: other_zone, key: "shared_key")
      subject.key = "shared_key"
      expect(subject).to be_valid
    end
  end

  describe "associations" do
    it "belongs to zone" do
      hotspot = described_class.new(valid_attributes)
      expect(hotspot.zone).to eq(city_zone)
    end

    it "optionally belongs to destination_zone" do
      hotspot = described_class.new(valid_attributes.merge(destination_zone: destination_zone))
      expect(hotspot.destination_zone).to eq(destination_zone)
    end
  end

  describe "scopes" do
    let!(:active_building) { create(:city_hotspot, zone: city_zone, active: true) }
    let!(:inactive_building) { create(:city_hotspot, zone: city_zone, active: false) }
    let!(:other_zone_building) { create(:city_hotspot, active: true) }

    describe ".for_zone" do
      it "returns only active hotspots for the zone" do
        result = described_class.for_zone(city_zone)
        expect(result).to include(active_building)
        expect(result).not_to include(inactive_building)
        expect(result).not_to include(other_zone_building)
      end
    end

    describe ".active" do
      it "returns only active hotspots" do
        result = described_class.active
        expect(result).to include(active_building)
        expect(result).not_to include(inactive_building)
      end
    end
  end

  describe "#can_interact?" do
    let(:character) { create(:character, level: 10) }
    let(:hotspot) { create(:city_hotspot, zone: city_zone, required_level: 5, active: true) }

    it "returns true when character meets requirements" do
      expect(hotspot.can_interact?(character)).to be true
    end

    it "returns false when inactive" do
      hotspot.update!(active: false)
      expect(hotspot.can_interact?(character)).to be false
    end

    it "returns false when action_type is none" do
      hotspot.update!(action_type: "none")
      expect(hotspot.can_interact?(character)).to be false
    end

    it "returns false when character level is too low" do
      hotspot.update!(required_level: 50)
      expect(hotspot.can_interact?(character)).to be false
    end
  end

  describe "#interaction_blocked_reason" do
    let(:character) { create(:character, level: 5) }
    let(:hotspot) { create(:city_hotspot, zone: city_zone, required_level: 1, active: true) }

    it "returns nil when can interact" do
      expect(hotspot.interaction_blocked_reason(character)).to be_nil
    end

    it "returns unavailable message when inactive" do
      hotspot.update!(active: false)
      expect(hotspot.interaction_blocked_reason(character)).to include("unavailable")
    end

    it "returns level message when level too low" do
      hotspot.update!(required_level: 20)
      expect(hotspot.interaction_blocked_reason(character)).to include("level 20")
    end
  end

  describe "#navigate_url" do
    let(:hotspot) { create(:city_hotspot, zone: city_zone) }

    it "returns nil for enter_zone action" do
      hotspot.update!(action_type: "enter_zone")
      expect(hotspot.navigate_url).to be_nil
    end

    it "returns feature URL for open_feature action" do
      hotspot.update!(action_type: "open_feature", action_params: {"feature" => "arena"})
      expect(hotspot.navigate_url).to eq("/arena")
    end

    it "returns nil for none action" do
      hotspot.update!(action_type: "none")
      expect(hotspot.navigate_url).to be_nil
    end
  end

  describe "#clickable?" do
    let(:hotspot) { create(:city_hotspot, zone: city_zone) }

    it "returns true for open_feature action" do
      hotspot.update!(action_type: "open_feature", active: true)
      expect(hotspot.clickable?).to be true
    end

    it "returns true for enter_zone action" do
      hotspot.update!(action_type: "enter_zone", active: true)
      expect(hotspot.clickable?).to be true
    end

    it "returns false for none action" do
      hotspot.update!(action_type: "none", active: true)
      expect(hotspot.clickable?).to be false
    end

    it "returns false when inactive" do
      hotspot.update!(action_type: "open_feature", active: false)
      expect(hotspot.clickable?).to be false
    end
  end

  describe "#display_icon" do
    let(:hotspot) { build(:city_hotspot, zone: city_zone) }

    it "returns building icon for building type" do
      hotspot.hotspot_type = "building"
      expect(hotspot.display_icon).to eq("🏛️")
    end

    it "returns exit icon for exit type" do
      hotspot.hotspot_type = "exit"
      expect(hotspot.display_icon).to eq("🚪")
    end

    it "returns tree icon for decoration type" do
      hotspot.hotspot_type = "decoration"
      expect(hotspot.display_icon).to eq("🌳")
    end
  end

  describe "#css_class" do
    let(:hotspot) { build(:city_hotspot, zone: city_zone, hotspot_type: "building") }

    it "returns CSS class with hotspot type" do
      expect(hotspot.css_class).to eq("city-hotspot city-hotspot--building")
    end
  end

  describe "#to_info_hash" do
    let(:hotspot) do
      create(:city_hotspot,
        zone: city_zone,
        key: "test",
        name: "Test Building",
        hotspot_type: "building",
        position_x: 100,
        position_y: 200,
        destination_zone: destination_zone,
        required_level: 5)
    end

    it "returns hash with hotspot info" do
      hash = hotspot.to_info_hash
      expect(hash[:key]).to eq("test")
      expect(hash[:name]).to eq("Test Building")
      expect(hash[:hotspot_type]).to eq("building")
      expect(hash[:position_x]).to eq(100)
      expect(hash[:position_y]).to eq(200)
      expect(hash[:destination]).to eq("Destination Zone")
      expect(hash[:required_level]).to eq(5)
    end
  end

  describe "constants" do
    it "defines HOTSPOT_TYPES" do
      expect(described_class::HOTSPOT_TYPES).to include("building", "exit", "decoration", "feature")
    end

    it "defines ACTION_TYPES" do
      expect(described_class::ACTION_TYPES).to include("enter_zone", "open_feature", "none")
    end

    it "defines FEATURE_ROUTES" do
      expect(described_class::FEATURE_ROUTES["arena"]).to eq("/arena")
      expect(described_class::FEATURE_ROUTES["crafting"]).to eq("/crafting_jobs")
    end
  end
end
