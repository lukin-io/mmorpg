# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::DefeatRecovery do
  let(:city) do
    node = Game::World::CityCatalog.node(Game::World::CityCatalog::STARTER_NODE_KEY)
    create(:zone, name: node["zone_name"], location_type: "city", width: 10, height: 10,
      metadata: {"city_node_key" => Game::World::CityCatalog::STARTER_NODE_KEY, "city_key" => "forpost"})
  end
  let(:outdoor) { create(:zone, name: "Defeat Woods", location_type: "outdoor") }
  let(:character) { create(:character, current_hp: 0, max_hp: 100, current_mp: 0, max_mp: 50) }
  let!(:position) { create(:character_position, character:, zone: outdoor, x: 5, y: 5) }

  before { city }

  it "restores vitals and moves a defeated character to the city hospital" do
    result = described_class.new(character:).call

    expect(result.recovered).to be(true)
    expect(result.path).to eq(city_building_path("hospital", defeat_recovered: 1))
    expect(character.reload.current_hp).to eq(character.effective_max_hp)
    expect(position.reload.zone).to eq(city)
  end

  it "does nothing when the character still has HP" do
    character.update!(current_hp: 12)

    result = described_class.new(character:).call

    expect(result.recovered).to be(false)
    expect(position.reload.zone).to eq(outdoor)
  end
end
