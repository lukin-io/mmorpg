# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorldHelper, type: :helper do
  describe "#format_time_remaining" do
    it "returns current-state text for nil" do
      expect(helper.format_time_remaining(nil)).to eq("сейчас")
    end

    it "returns current-state text for zero" do
      expect(helper.format_time_remaining(0)).to eq("сейчас")
    end

    it "returns current-state text for negative numbers" do
      expect(helper.format_time_remaining(-5)).to eq("сейчас")
    end

    it "formats seconds only" do
      expect(helper.format_time_remaining(45)).to eq("45 сек.")
    end

    it "formats minutes and seconds" do
      expect(helper.format_time_remaining(90)).to eq("1 мин. 30 сек.")
    end

    it "formats minutes only when no remaining seconds" do
      expect(helper.format_time_remaining(120)).to eq("2 мин.")
    end

    it "formats hours and minutes" do
      expect(helper.format_time_remaining(3900)).to eq("1 ч. 5 мин.")
    end

    it "formats hours only when no remaining minutes" do
      expect(helper.format_time_remaining(7200)).to eq("2 ч.")
    end
  end

  describe "#in_city?" do
    let(:city_zone) { create(:zone, name: "Форпост", location_type: "city") }
    let(:outdoor_zone) { create(:zone, name: "Окрестность Форпоста", location_type: "outdoor") }
    let(:character) { create(:character) }

    it "returns true for city location type" do
      position = create(:character_position, character: character, zone: city_zone)
      expect(helper.in_city?(position)).to be true
    end

    it "returns false for outdoor location type" do
      position = create(:character_position, character: character, zone: outdoor_zone)
      expect(helper.in_city?(position)).to be false
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
