# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::GuardTowerRoutes do
  let(:city) { create(:zone, :city_node, name: "Central Square") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone: city, x: 0, y: 0) }
  let!(:district) { create(:city_hotspot, :district, zone: city, key: "go_forpost1", name: "To Residential") }

  it "returns live district offers for the current node" do
    routes = described_class.new(character:).call

    expect(routes.map { |route| route.hotspot.id }).to eq([district.id])
    expect(routes.first.offer).to be_present
  end
end
