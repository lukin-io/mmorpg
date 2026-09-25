# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PlayableRegionBuilder do
  let(:zone_name) { "Пепельный Берег" }

  before do
    Zone.find_or_create_by!(name: zone_name) do |z|
      z.location_type = "outdoor"
      z.width = 1000
      z.height = 1000
    end
    create(:npc_template, npc_key: "av_test_bot", name: "Тестовый бот", level: 5, role: "hostile")
  end

  it "creates landmark cells, fortresses, and dungeon floor bots" do
    result = described_class.new.call

    expect(result.fortresses).to be >= 5
    expect(MapTileTemplate.find_by(zone: zone_name, x: 50, y: 50).metadata.dig("landmark", "kind")).to eq("fortress")
    expect(MapTileTemplate.find_by(zone: zone_name, x: 28, y: 28).metadata.dig("landmark", "kind")).to eq("dungeon")
    expect(WorldFortress.find_by(fortress_key: "fort_heart")).to be_present
    expect(result.dungeon_npcs).to be >= 1
  end
end
