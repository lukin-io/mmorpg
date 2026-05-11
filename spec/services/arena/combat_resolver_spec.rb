# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatResolver do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:attacker) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:defender) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }
  let(:arena_match) { create(:arena_match, status: :live) }
  let(:attacker_participation) { create(:arena_participation, arena_match:, character: attacker, user: user1, team: "a") }
  let(:defender_participation) { create(:arena_participation, arena_match:, character: defender, user: user2, team: "b") }
  let(:rng) { instance_double(Random) }
  let(:resolver) { described_class.new(match: arena_match, rng:) }

  before do
    create(:character_position, character: attacker)
    create(:character_position, character: defender)
  end

  it "resolves a non-critical physical hit with body-part damage" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 99)
    allow(rng).to receive(:rand).with(1..5).and_return(3)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :hit, critical: false, blocked: false)
    expect(result[:damage]).to be >= 0
  end

  it "resolves a miss before dodge, block, critical, and damage" do
    allow(rng).to receive(:rand).with(100).and_return(99)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "head"
    )

    expect(result).to include(outcome: :miss, miss: true, damage: 0)
  end

  it "resolves a dodge after a successful hit roll" do
    allow(rng).to receive(:rand).with(100).and_return(0, 0)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :dodge, dodge: true, damage: 0)
  end

  it "resolves a successful selected block before critical and damage" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 0)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso",
      block: {
        "action_key" => "torso_block",
        "body_parts" => ["torso"],
        "block_table" => "normal"
      }
    )

    expect(result).to include(
      outcome: :blocked,
      blocked: true,
      damage: 0,
      block_key: "torso_block",
      block_table: "normal"
    )
    expect(result[:block_attempted]).to be true
    expect(result[:block_success]).to be true
    expect(result[:block_roll]).to eq(0)
  end

  it "allows a selected block to fail before critical and damage" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 99, 99)
    allow(rng).to receive(:rand).with(1..5).and_return(3)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso",
      block: {
        "action_key" => "torso_block",
        "body_parts" => ["torso"],
        "block_table" => "normal"
      }
    )

    expect(result).to include(outcome: :hit, blocked: false, block_attempted: true, block_success: false)
    expect(result[:damage]).to be >= 0
  end

  it "marks critical hits and applies critical damage multiplier" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 0)
    allow(rng).to receive(:rand).with(1..5).and_return(3)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "aimed",
      body_part: "head"
    )

    expect(result).to include(outcome: :hit, critical: true)
    expect(result[:crit_chance]).to be > 0
  end
end
