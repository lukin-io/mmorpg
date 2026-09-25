# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::InjuryResolver do
  it "does not treat world_npc + combat_trauma metadata as guaranteed heavy" do
    character = create(:character, current_hp: 0, max_hp: 100)
    match = create(
      :arena_match,
      :completed,
      metadata: {"trauma_percent" => 80, "source" => "world_npc", "combat_trauma" => true}
    )
    create(:arena_participation, arena_match: match, character:, user: character.user, result: "defeat", team: "a")

    results = described_class.new(match:, rng: Random.new(6)).call

    expect(results.first.severity).to eq("light")
    expect(results.first.severity).not_to eq("heavy")
  end
end
