require "rails_helper"

RSpec.describe Game::Exploration::EncounterResolver do
  let(:zone) do
    create(
      :zone,
      biome: "forest",
      encounter_table: {"forest" => [{"name" => "Wolf", "weight" => 100, "kind" => "pve"}]}
    )
  end
  let(:resolver) { described_class.new }

  it "returns encounters based on zone tables" do
    encounter = resolver.resolve(zone:, biome: "forest", tile_metadata: {}, rng: Random.new(1))

    expect(encounter[:name]).to eq("Wolf")
    expect(encounter[:kind]).to eq("pve")
  end
end
