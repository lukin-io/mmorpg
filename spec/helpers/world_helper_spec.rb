# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorldHelper, type: :helper do
  describe "#terrain_icon" do
    it "returns correct icon for plains" do
      expect(helper.terrain_icon("plains")).to eq("🌾")
    end

    it "returns correct icon for forest" do
      expect(helper.terrain_icon("forest")).to eq("🌲")
    end

    it "returns correct icon for mountain" do
      expect(helper.terrain_icon("mountain")).to eq("⛰️")
    end

    it "returns correct icon for river" do
      expect(helper.terrain_icon("river")).to eq("🌊")
    end

    it "returns correct icon for city" do
      expect(helper.terrain_icon("city")).to eq("🏙️")
    end

    it "returns default icon for unknown terrain" do
      expect(helper.terrain_icon("unknown")).to eq("🗺️")
    end
  end

  describe "#npc_icon" do
    it "returns wolf icon for wolf NPC" do
      expect(helper.npc_icon("Forest Wolf")).to eq("🐺")
    end

    it "returns goblin icon for goblin NPC" do
      expect(helper.npc_icon("Goblin Scout")).to eq("👺")
    end

    it "returns spider icon for spider NPC" do
      expect(helper.npc_icon("Giant Spider")).to eq("🕷️")
    end

    it "returns bandit icon for bandit NPC" do
      expect(helper.npc_icon("Bandit Leader")).to eq("🥷")
    end

    it "returns default icon for unknown NPC" do
      expect(helper.npc_icon("Unknown Entity")).to eq("👤")
    end
  end

  describe "#format_time_remaining" do
    it "returns 'now' for nil" do
      expect(helper.format_time_remaining(nil)).to eq("now")
    end

    it "returns 'now' for zero" do
      expect(helper.format_time_remaining(0)).to eq("now")
    end

    it "returns 'now' for negative numbers" do
      expect(helper.format_time_remaining(-5)).to eq("now")
    end

    it "formats seconds only" do
      expect(helper.format_time_remaining(45)).to eq("45s")
    end

    it "formats minutes and seconds" do
      expect(helper.format_time_remaining(90)).to eq("1m 30s")
    end

    it "formats minutes only when no remaining seconds" do
      expect(helper.format_time_remaining(120)).to eq("2m")
    end

    it "formats hours and minutes" do
      expect(helper.format_time_remaining(3900)).to eq("1h 5m")
    end

    it "formats hours only when no remaining minutes" do
      expect(helper.format_time_remaining(7200)).to eq("2h")
    end
  end

  describe "#in_city?" do
    let(:city_zone) { create(:zone, name: "Capital", biome: "city") }
    let(:plains_zone) { create(:zone, name: "Plains", biome: "plains") }
    let(:character) { create(:character) }

    it "returns true for city biome" do
      position = create(:character_position, character: character, zone: city_zone)
      expect(helper.in_city?(position)).to be true
    end

    it "returns false for non-city biome" do
      position = create(:character_position, character: character, zone: plains_zone)
      expect(helper.in_city?(position)).to be false
    end

    it "returns true when metadata zone_type is city" do
      zone_with_meta = create(:zone, biome: "forest", metadata: {"zone_type" => "city"})
      position = create(:character_position, character: character, zone: zone_with_meta)
      expect(helper.in_city?(position)).to be true
    end
  end

  describe "#format_coordinates" do
    it "formats coordinates correctly" do
      expect(helper.format_coordinates(10, 20)).to eq("[10, 20]")
    end

    it "handles zero coordinates" do
      expect(helper.format_coordinates(0, 0)).to eq("[0, 0]")
    end

    it "handles large coordinates" do
      expect(helper.format_coordinates(999, 888)).to eq("[999, 888]")
    end
  end

  describe "#direction_arrow" do
    it "returns correct arrow for north" do
      expect(helper.direction_arrow(:north)).to eq("▲")
    end

    it "returns correct arrow for south" do
      expect(helper.direction_arrow(:south)).to eq("▼")
    end

    it "returns correct arrow for east" do
      expect(helper.direction_arrow(:east)).to eq("▶")
    end

    it "returns correct arrow for west" do
      expect(helper.direction_arrow(:west)).to eq("◀")
    end

    it "returns correct arrow for diagonal directions" do
      expect(helper.direction_arrow(:northeast)).to eq("↗")
      expect(helper.direction_arrow(:northwest)).to eq("↖")
      expect(helper.direction_arrow(:southeast)).to eq("↘")
      expect(helper.direction_arrow(:southwest)).to eq("↙")
    end

    it "returns default for unknown direction" do
      expect(helper.direction_arrow(:unknown)).to eq("•")
    end

    it "handles string input" do
      expect(helper.direction_arrow("north")).to eq("▲")
    end
  end
end
