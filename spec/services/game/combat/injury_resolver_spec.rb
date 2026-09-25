# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::InjuryResolver do
  let(:character) { create(:character, current_hp: 0, max_hp: 100) }

  def defeat!(match)
    create(:arena_participation, arena_match: match, character:, user: character.user, result: "defeat", team: "a")
  end

  it "applies only light/medium on PvE defeat and never heavy" do
    match = create(:arena_match, :completed, metadata: {"source" => "world_npc", "is_npc_fight" => true})
    defeat!(match)
    create(:arena_participation, :npc, arena_match: match, team: "b", result: "victory")

    results = described_class.new(match:, rng: Random.new(6)).call

    expect(results.first.severity).to eq("light")
    expect(Game::Combat::InjuryState::SEVERITIES).to include("medium")
    severities = Game::Combat::InjuryState.new(character: character.reload).active.map { |r| r["severity"] }
    expect(severities).not_to include("heavy", "combat")
  end

  it "may apply medium on PvE with a low roll" do
    match = create(:arena_match, :completed, metadata: {"source" => "world_npc"})
    defeat!(match)

    results = described_class.new(match:, rng: Random.new(22)).call

    expect(results.first.severity).to eq("medium")
  end

  it "guarantees heavy trauma on bloody PvP defeat" do
    match = create(
      :arena_match,
      :completed,
      metadata: {"source" => "world_pvp", "assault_scroll_kind" => "bloody"}
    )
    defeat!(match)
    winner = create(:character)
    create(:arena_participation, arena_match: match, character: winner, user: winner.user, team: "b", result: "victory")

    results = described_class.new(match:, rng: Random.new(1)).call

    expect(results.first.severity).to eq("heavy")
    expect(Game::Combat::InjuryState.new(character: character.reload).blocks_movement?).to be(true)
  end

  it "ignores crit intensity and follows assault scroll kind" do
    match = create(
      :arena_match,
      :completed,
      trauma_percent: 30,
      metadata: {"assault_scroll_kind" => "peaceful", "combat_trauma" => false}
    )
    create(
      :arena_participation,
      arena_match: match,
      character:,
      user: character.user,
      team: "a",
      result: "defeat",
      metadata: {
        "critical_hits_taken" => 9,
        "critical_damage_taken" => 999,
        "head_hits_taken" => 9
      }
    )

    results = described_class.new(match:, rng: Random.new(1)).call

    expect(results).to be_empty
  end
end
