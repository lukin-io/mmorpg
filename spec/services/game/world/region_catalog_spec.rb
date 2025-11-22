# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::RegionCatalog do
  subject(:catalog) { described_class.instance }

  describe "#region_for_territory" do
    it "returns a region matching the key from config" do
      region = catalog.region_for_territory("everfall_core")

      expect(region).to be_present
      expect(region.name).to eq("Everfall Capital")
      expect(region.tax_bonus_rate).to be_positive
    end
  end

  describe "#region_for_zone" do
    it "matches zones defined inside the region config" do
      zone = instance_double("Zone", name: "Elder Grove")

      expect(catalog.region_for_zone(zone)&.key).to eq("ashen_forest")
    end
  end

  describe "#resource_nodes_for" do
    it "exposes deterministic resource node configuration" do
      nodes = catalog.resource_nodes_for("ashen_forest")

      expect(nodes).to be_an(Array)
      expect(nodes.first).to include("resource_key" => "emberbloom")
    end
  end
end
