# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityHotspotService do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, level: 10) }
  let(:city_zone) { create(:zone, name: "Test City", biome: "city", width: 20, height: 20) }
  let(:destination_zone) { create(:zone, name: "Destination", biome: "plains", width: 20, height: 20) }
  let!(:spawn_point) { create(:spawn_point, zone: destination_zone, x: 5, y: 5, default_entry: true) }
  let!(:position) { create(:character_position, character: character, zone: city_zone, x: 5, y: 5) }

  subject { described_class.new(character: character, zone: city_zone) }

  describe "#city_zone?" do
    it "returns true for city biome" do
      expect(subject.city_zone?).to be true
    end

    it "returns false for non-city biome" do
      plains_zone = create(:zone, biome: "plains")
      service = described_class.new(character: character, zone: plains_zone)
      expect(service.city_zone?).to be false
    end

    it "returns false for nil zone" do
      service = described_class.new(character: character, zone: nil)
      expect(service.city_zone?).to be false
    end
  end

  describe "#hotspots_for_display" do
    let!(:active_hotspot) { create(:city_hotspot, zone: city_zone, active: true, required_level: 1) }
    let!(:inactive_hotspot) { create(:city_hotspot, zone: city_zone, active: false) }

    it "returns hotspot info hashes" do
      result = subject.hotspots_for_display
      expect(result).to be_an(Array)
      expect(result.first).to include(:id, :name, :can_interact)
    end

    it "excludes inactive hotspots" do
      result = subject.hotspots_for_display
      keys = result.map { |h| h[:id] }
      expect(keys).to include(active_hotspot.id)
      expect(keys).not_to include(inactive_hotspot.id)
    end

    it "includes can_interact and blocked_reason" do
      result = subject.hotspots_for_display
      hotspot_info = result.find { |h| h[:id] == active_hotspot.id }
      expect(hotspot_info).to have_key(:can_interact)
      expect(hotspot_info).to have_key(:blocked_reason)
    end

    it "returns empty array for non-city zone" do
      plains_zone = create(:zone, biome: "plains")
      service = described_class.new(character: character, zone: plains_zone)
      expect(service.hotspots_for_display).to eq([])
    end
  end

  describe "#hotspots" do
    let!(:hotspot1) { create(:city_hotspot, zone: city_zone, z_index: 1, active: true) }
    let!(:hotspot2) { create(:city_hotspot, zone: city_zone, z_index: 2, active: true) }

    it "returns hotspot records" do
      result = subject.hotspots
      expect(result).to include(hotspot1, hotspot2)
    end

    it "orders by z_index" do
      result = subject.hotspots.to_a
      expect(result.first).to eq(hotspot1)
      expect(result.second).to eq(hotspot2)
    end
  end

  describe "#interact!" do
    context "with valid building hotspot" do
      let!(:building) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "open_feature",
          action_params: {"feature" => "arena"},
          required_level: 1,
          active: true)
      end

      it "returns success result" do
        result = subject.interact!(building.id)
        expect(result.success).to be true
      end

      it "returns redirect_url for feature" do
        result = subject.interact!(building.id)
        expect(result.redirect_url).to eq("/arena")
      end

      it "includes hotspot in result" do
        result = subject.interact!(building.id)
        expect(result.hotspot).to eq(building)
      end
    end

    context "with exit hotspot" do
      let!(:exit_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "enter_zone",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns success result" do
        result = subject.interact!(exit_hotspot.id)
        expect(result.success).to be true
      end

      it "updates character position to destination zone" do
        subject.interact!(exit_hotspot.id)
        position.reload
        expect(position.zone).to eq(destination_zone)
      end

      it "uses spawn point coordinates" do
        subject.interact!(exit_hotspot.id)
        position.reload
        expect(position.x).to eq(spawn_point.x)
        expect(position.y).to eq(spawn_point.y)
      end

      it "returns destination_zone in result" do
        result = subject.interact!(exit_hotspot.id)
        expect(result.destination_zone).to eq(destination_zone)
      end
    end

    context "when hotspot not found" do
      it "returns failure result" do
        result = subject.interact!(99999)
        expect(result.success).to be false
        expect(result.message).to include("not found")
      end
    end

    context "when character level too low" do
      let!(:high_level_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          required_level: 50,
          active: true)
      end

      it "returns failure result" do
        result = subject.interact!(high_level_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("level 50")
      end
    end

    context "when hotspot is inactive" do
      let!(:inactive_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          active: false)
      end

      it "returns failure result" do
        result = subject.interact!(inactive_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("unavailable")
      end
    end

    context "when exit hotspot has no destination" do
      let!(:broken_exit) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "enter_zone",
          destination_zone: nil,
          required_level: 1,
          active: true)
      end

      it "returns failure result" do
        result = subject.interact!(broken_exit.id)
        expect(result.success).to be false
        expect(result.message).to include("nowhere")
      end
    end

    context "when character has no position" do
      before { position.destroy }

      let!(:exit_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "enter_zone",
          destination_zone: destination_zone,
          required_level: 1,
          active: true)
      end

      it "returns failure result" do
        character.reload
        result = subject.interact!(exit_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("position")
      end
    end

    context "with decoration hotspot (action_type: none)" do
      let!(:decoration) do
        create(:city_hotspot,
          zone: city_zone,
          action_type: "none",
          hotspot_type: "decoration",
          required_level: 1,
          active: true)
      end

      it "returns failure result" do
        result = subject.interact!(decoration.id)
        expect(result.success).to be false
        expect(result.message).to include("cannot interact")
      end
    end

    context "with unimplemented feature (housing)" do
      let!(:housing_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          key: "housing",
          name: "Housing District",
          hotspot_type: "feature",
          action_type: "open_feature",
          action_params: {"feature" => "housing"},
          required_level: 1,
          active: true)
      end

      it "returns failure with 'coming soon' message" do
        result = subject.interact!(housing_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("coming soon")
        expect(result.redirect_url).to be_nil
      end
    end

    context "with unimplemented feature (clinic)" do
      let!(:clinic_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          key: "clinic",
          name: "Clinic",
          hotspot_type: "feature",
          action_type: "open_feature",
          action_params: {"feature" => "clinic"},
          required_level: 1,
          active: true)
      end

      it "returns failure with 'coming soon' message" do
        result = subject.interact!(clinic_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("coming soon")
      end
    end

    context "with unimplemented feature (healing)" do
      let!(:healing_hotspot) do
        create(:city_hotspot,
          zone: city_zone,
          key: "healing",
          name: "Healing",
          hotspot_type: "feature",
          action_type: "open_feature",
          action_params: {"feature" => "healing"},
          required_level: 1,
          active: true)
      end

      it "returns failure with 'coming soon' message" do
        result = subject.interact!(healing_hotspot.id)
        expect(result.success).to be false
        expect(result.message).to include("coming soon")
      end
    end
  end

  describe "Result struct" do
    it "has expected attributes" do
      result = described_class::Result.new(
        success: true,
        message: "Test",
        hotspot: nil,
        redirect_url: "/test",
        destination_zone: nil
      )
      expect(result.success).to be true
      expect(result.message).to eq("Test")
      expect(result.redirect_url).to eq("/test")
    end
  end
end
