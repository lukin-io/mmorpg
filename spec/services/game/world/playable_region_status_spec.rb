# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PlayableRegionStatus do
  let(:result) do
    Game::World::PlayableRegionBuilder::Result.new(
      cells_created: 3,
      cells_updated: 5,
      fortresses: 2,
      dungeon_npcs: 4,
      skipped: 1
    )
  end

  around do |example|
    previous = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = previous
  end

  it "records and reads the last builder outcome" do
    payload = described_class.record!(result:, source: "boot")

    expect(payload["source"]).to eq("boot")
    expect(payload["cells_created"]).to eq(3)
    expect(payload["fortresses"]).to eq(2)
    expect(described_class.read["cells_updated"]).to eq(5)
  end
end
