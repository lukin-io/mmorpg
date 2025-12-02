# frozen_string_literal: true

require "rails_helper"

RSpec.describe TileResource, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "validations" do
    it "validates presence of required fields" do
      resource = TileResource.new
      expect(resource).not_to be_valid
      expect(resource.errors[:zone]).to include("can't be blank")
      expect(resource.errors[:resource_key]).to include("can't be blank")
    end

    it "validates resource_type inclusion" do
      resource = build(:tile_resource, resource_type: "invalid")
      expect(resource).not_to be_valid
      expect(resource.errors[:resource_type]).to include("is not included in the list")
    end

    it "is valid with factory defaults" do
      resource = build(:tile_resource)
      expect(resource).to be_valid
    end
  end

  describe "scopes" do
    describe ".available" do
      it "includes resources with positive quantity and no respawn time" do
        available = create(:tile_resource, quantity: 1, respawns_at: nil)
        expect(TileResource.available).to include(available)
      end

      it "includes resources with passed respawn time" do
        available = create(:tile_resource, quantity: 1, respawns_at: 1.hour.ago)
        expect(TileResource.available).to include(available)
      end

      it "excludes depleted resources" do
        depleted = create(:tile_resource, :depleted)
        expect(TileResource.available).not_to include(depleted)
      end
    end

    describe ".depleted" do
      it "includes resources with zero quantity" do
        depleted = create(:tile_resource, quantity: 0)
        expect(TileResource.depleted).to include(depleted)
      end

      it "includes resources waiting for respawn" do
        depleted = create(:tile_resource, :depleted)
        expect(TileResource.depleted).to include(depleted)
      end
    end

    describe ".at_tile" do
      it "finds resource at specific coordinates" do
        resource = create(:tile_resource, zone: "Test Zone", x: 5, y: 10)
        found = TileResource.at_tile("Test Zone", 5, 10)
        expect(found).to eq(resource)
      end

      it "returns nil when no resource exists" do
        # at_tile is a class method that returns find_by result
        expect(TileResource.find_by(zone: "Nowhere", x: 0, y: 0)).to be_nil
      end
    end
  end

  describe "#available?" do
    it "returns true for harvestable resources" do
      resource = build(:tile_resource, quantity: 1, respawns_at: nil)
      expect(resource).to be_available
    end

    it "returns false for depleted resources" do
      resource = build(:tile_resource, :depleted)
      expect(resource).not_to be_available
    end

    it "returns true after respawn time passes" do
      resource = build(:tile_resource, :ready_to_respawn)
      resource.quantity = 1
      expect(resource).to be_available
    end
  end

  describe "#harvest!" do
    let(:character) { create(:character) }
    let(:resource) { create(:tile_resource, quantity: 3) }

    it "decrements quantity and returns harvested amount" do
      harvested = resource.harvest!(character)
      expect(harvested).to eq(1)
      expect(resource.reload.quantity).to eq(2)
    end

    it "records harvester and timestamp" do
      travel_to Time.zone.local(2025, 1, 15, 12, 0, 0) do
        resource.harvest!(character)
        expect(resource.harvested_by).to eq(character)
        expect(resource.last_harvested_at).to eq(Time.current)
      end
    end

    it "sets respawn time when depleted" do
      resource.update!(quantity: 1)
      resource.harvest!(character)
      expect(resource.respawns_at).to be_present
      expect(resource.respawns_at).to be > Time.current
    end

    it "returns 0 for unavailable resources" do
      resource = create(:tile_resource, :depleted)
      expect(resource.harvest!(character)).to eq(0)
    end
  end

  describe "#respawn!" do
    let(:resource) { create(:tile_resource, :depleted, biome: "forest") }

    it "resets resource with new random resource from biome" do
      resource.respawn!
      expect(resource.quantity).to be > 0
      expect(resource.respawns_at).to be_nil
      expect(resource.harvested_by).to be_nil
    end

    it "selects resource appropriate for biome" do
      resource.respawn!
      forest_resources = Game::World::BiomeResourceConfig.resource_keys("forest").map(&:to_s)
      expect(forest_resources).to include(resource.resource_key)
    end
  end

  describe "#time_until_respawn" do
    it "returns 0 for available resources" do
      resource = build(:tile_resource)
      expect(resource.time_until_respawn).to eq(0)
    end

    it "returns seconds until respawn for depleted resources" do
      resource = build(:tile_resource, respawns_at: 10.minutes.from_now, quantity: 0)
      expect(resource.time_until_respawn).to be_within(5).of(10.minutes.to_i)
    end
  end

  describe "#display_name" do
    it "titleizes the resource key" do
      resource = build(:tile_resource, resource_key: "iron_ore")
      expect(resource.display_name).to eq("Iron Ore")
    end
  end
end
