# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::CityBuildingCatalog do
  let(:character) { create(:character, level: 10) }
  let(:city) { create(:zone, :city_node) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:market) { create(:city_hotspot, :read_only_city_building, zone: city) }

  it "returns only documented read-only city buildings" do
    expect(described_class.fetch("market")).to include("title" => "Market", "kind" => "market")
    expect(described_class.fetch("hospital")).to include("kind" => "hospital")
    expect(described_class.fetch(nil)).to be_nil
    expect(described_class.fetch("bank")).to be_nil
  end

  it "requires the character to be at the building's current city node" do
    expect(described_class.accessible?(character:, building_key: "market")).to be true

    position.update!(zone: create(:zone, :mvp_outdoor_region), x: 7, y: 0)

    expect(described_class.accessible?(character:, building_key: "market")).to be false
  end

  it "rejects inactive, level-blocked, null, and unsupported building access" do
    market.update!(active: false)
    expect(described_class.accessible?(character:, building_key: "market")).to be false

    market.update!(active: true, required_level: character.level + 1)
    expect(described_class.accessible?(character:, building_key: "market")).to be false
    expect(described_class.accessible?(character:, building_key: nil)).to be false
    expect(described_class.accessible?(character:, building_key: "bank")).to be false
  end
end
