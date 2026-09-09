# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/starter_encounter_bootstrap")

RSpec.describe Seeds::StarterEncounterBootstrap, type: :model do
  let(:zone_name) { "Outpost Surroundings" }
  let(:zone_config) { Game::World::OutdoorNpcConfig.config.fetch(:outpost_surroundings) }
  let(:definition) { zone_config.fetch(:starter_npcs).find { |npc| npc.values_at(:x, :y) == [15, 7] }.deep_dup }
  let(:templates) do
    %w[wilderness_bandit wilderness_robber].index_with do |key|
      create(:npc_template, npc_key: key)
    end
  end

  def bootstrap(definitions = [definition])
    described_class.new(zone_name:, definitions:, templates:).call
  end

  def load_seed
    allow($stdout).to receive(:puts)
    Rails.application.load_seed
  end

  it "creates a captured group once without changing its eligible cell or a saved character position" do
    region = create(:zone, :mvp_outdoor_region, name: zone_name)
    cell = create(:map_tile_template, zone: zone_name, x: 15, y: 7,
      metadata: {"source_map" => "m_1009_999", "managed_note" => "Retain cell"})
    position = create(:character_position, zone: region, x: 15, y: 7)
    original_cell = cell.attributes

    expect { bootstrap }.to change(TileNpc, :count).by(1)

    npc = TileNpc.find_by!(zone: zone_name, x: 15, y: 7)
    expect(npc).to have_attributes(npc_key: "wilderness_bandit", level: 7, current_hp: 155, max_hp: 155)
    expect(npc.metadata).to include(
      "seed_scope" => "starter_encounter_bootstrap", "bootstrap_source_map" => "m_1009_999",
      "source_map" => "m_1009_999", "roster_source_map" => "m_1008_1007"
    )
    expect(npc.encounter_roster_samples).to eq(definition.dig(:metadata, :encounter_rosters).map(&:deep_stringify_keys))
    expect(npc.passive_delay_windows).to eq([
      {"key" => "user_reported_five_to_six_minutes", "min_seconds" => 300, "max_seconds" => 360}
    ])
    original_npc = npc.attributes
    expect(bootstrap).to eq([npc.id])
    expect(npc.reload.attributes).to eq(original_npc)
    expect(cell.reload.attributes).to eq(original_cell)
    expect(position.reload).to have_attributes(zone: region, x: 15, y: 7)
    expect(NpcTemplate.count).to eq(2)
  end

  it "preserves an existing managed placement even when legacy cleanup recognizes its source marker" do
    npc = create(:tile_npc, zone: zone_name, x: 15, y: 7, current_hp: 9,
      metadata: {"seed_source" => "outdoor_npcs.yml", "active" => false, "managed_note" => "Keep custom roster"})
    original = npc.attributes

    load_seed

    expect(npc.reload.attributes).to eq(original)
    expect(TileNpc.where(zone: zone_name, x: 15, y: 7).count).to eq(1)
  end

  it "preserves moved and disabled bootstrap placements instead of duplicating their original source on reseed" do
    load_seed
    npc = TileNpc.find_by!(zone: zone_name, x: 15, y: 7)
    npc.update!(x: 80, y: 81, current_hp: 9, metadata: npc.metadata.merge(
      "source_map" => "managed_destination", "active" => false, "managed_note" => "Moved group"
    ))
    original = npc.attributes

    expect { load_seed }.not_to change(TileNpc, :count)

    expect(npc.reload.attributes).to eq(original)
    expect(TileNpc.where(zone: zone_name, x: 15, y: 7)).to be_empty

    changed_config = Game::World::OutdoorNpcConfig.config.deep_dup
    changed_config.fetch(:outpost_surroundings)[:starter_npcs] = []
    allow(Game::World::OutdoorNpcConfig).to receive(:config).and_return(changed_config)
    expect { load_seed }.not_to change(TileNpc, :count)
    expect(npc.reload.attributes).to eq(original)
  end

  it "requires an existing cell and respects managed passability and blocked metadata" do
    expect { bootstrap }.not_to change(TileNpc, :count)
    cell = create(:map_tile_template, zone: zone_name, x: 15, y: 7, passable: false)
    expect { bootstrap }.not_to change(TileNpc, :count)
    cell.update!(passable: true, metadata: {"blocked" => true})
    expect { bootstrap }.not_to change(TileNpc, :count)
  end

  it "does not bootstrap over an entrance, including an inactive managed entrance" do
    create(:map_tile_template, zone: zone_name, x: 15, y: 7)
    entrance = create(:tile_building, :world_location, :inactive, zone: zone_name, x: 15, y: 7)
    original = entrance.attributes

    expect { bootstrap }.not_to change(TileNpc, :count)

    expect(entrance.reload.attributes).to eq(original)
  end

  it "keeps the evidenced pond empty without treating every water annotation as safe" do
    cell = create(:map_tile_template, zone: zone_name, x: 15, y: 7, metadata: {"source_map" => "m_1007_1002"})
    expect { bootstrap }.not_to change(TileNpc, :count)
    cell.update!(metadata: {"atlas" => {"id" => "8-326"}})
    expect { bootstrap }.not_to change(TileNpc, :count)
    cell.update!(metadata: {"atlas" => {"water" => true}})
    expect { bootstrap }.to change(TileNpc, :count).by(1)
  end

  it "treats an empty derived configuration as a no-op" do
    expect(bootstrap([])).to eq([])
    expect(TileNpc.count).to eq(0)
  end
end
