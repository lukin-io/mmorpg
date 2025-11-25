# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe Game::Quests::MapOverlayPresenter do
  let(:character) { create(:character) }
  let(:quest) do
    create(:quest,
      map_overlays: {"nodes" => [{"type" => "objective", "label" => "Hidden Cache", "zone" => "Frostmarch"}]})
  end
  let(:region) { double("Region", key: "grove", name: "Sunken Grove") }
  let(:region_catalog) { instance_double("Game::World::RegionCatalog", all: [region]) }
  let(:population_directory) { instance_double("Game::World::PopulationDirectory") }

  before do
    quest.quest_steps.create!(position: 1, step_type: "dialogue", npc_key: "elder_miri", content: {})
    quest.quest_objectives.create!(position: 1, objective_type: "gather", metadata: {"resource_key" => "moonleaf"})
    allow(region_catalog).to receive(:resource_nodes_for).with("grove").and_return(["moonleaf"])
    allow(Game::World::PopulationDirectory).to receive(:instance).and_return(population_directory)
    allow(population_directory).to receive(:npc).with("elder_miri")
      .and_return(OpenStruct.new(name: "Elder Miri", zone_key: "Skywatch"))
  end

  it "merges explicit nodes, NPCs, and resource pins" do
    pins = described_class.new(quest:, character:, region_catalog:).pins

    expect(pins).to include(hash_including("label" => "Hidden Cache", "type" => "objective"))
    expect(pins).to include(hash_including("label" => "Elder Miri", "type" => "npc", "zone" => "Skywatch"))
    expect(pins).to include(hash_including("label" => "Moonleaf", "type" => "resource", "zone" => "Sunken Grove"))
  end
end
