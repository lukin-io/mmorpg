# frozen_string_literal: true

require "rails_helper"

RSpec.describe Zone, type: :model do
  describe "region dimensions" do
    it "supports the single 1000 x 1000 MVP outdoor region" do
      region = build(:zone, :mvp_outdoor_region)

      expect(region).to be_valid
      expect(region).to have_attributes(location_type: "outdoor", width: 1000, height: 1000)
    end

    it "accepts the minimum positive boundary" do
      expect(build(:zone, :minimum_size)).to be_valid
    end

    it "rejects zero, negative, and null dimensions" do
      [
        build(:zone, width: 0),
        build(:zone, height: -1),
        build(:zone, width: nil)
      ].each do |region|
        expect(region).not_to be_valid
      end
    end
  end

  describe "location types" do
    it "distinguishes outdoor regions from cities" do
      expect(build(:zone, :mvp_outdoor_region)).to be_outdoor
      expect(build(:zone, :city)).to be_city
    end

    it "rejects a generic legacy location type" do
      region = build(:zone, location_type: "generic_location")

      expect(region).not_to be_valid
      expect(region.errors[:location_type]).to be_present
    end
  end

  describe "city node identity" do
    it "exposes the stable node key and player-facing title" do
      node = build(:zone, :city_node)

      expect(node.city_node_key).to eq("city2_1")
      expect(node.display_name).to eq("Central Square")
    end

    it "falls back to the zone name when city metadata is null or absent" do
      zone = build(:zone, name: "Fallback Zone", metadata: {})

      expect(zone.city_node_key).to be_nil
      expect(zone.display_name).to eq("Fallback Zone")
    end
  end
end
