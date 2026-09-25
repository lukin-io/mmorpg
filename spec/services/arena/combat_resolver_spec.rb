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
    described_class.reload_table!
    create(:character_position, character: attacker)
    create(:character_position, character: defender)
  end

  def stub_percent_rolls(*rolls)
    allow(rng).to receive(:rand).with(100).and_return(*rolls)
  end

  def stub_base_hit_fraction(fraction)
    allow(rng).to receive(:rand).with(no_args).and_return(fraction)
  end

  it "resolves a non-critical physical hit with body-part damage" do
    stub_percent_rolls(0, 99, 99) # hit, no dodge, no crit
    stub_base_hit_fraction(0.5)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :hit, critical: false, blocked: false)
    expect(result[:damage]).to be >= 1
  end

  it "resolves a miss before dodge, block, critical, and damage" do
    stub_percent_rolls(99)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "head"
    )

    expect(result).to include(outcome: :miss, miss: true, damage: 0)
  end

  it "resolves a dodge after a successful hit roll using evasion formula" do
    allow(defender).to receive(:dodge_bonus).and_return(40)
    allow(attacker).to receive(:accuracy_bonus).and_return(0)
    # evasion_chance = 40*1.5 - 0 = 60 → roll 0 dodges
    stub_percent_rolls(0, 0)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :dodge, dodge: true, damage: 0)
    expect(result[:dodge_chance]).to eq(60.0)
  end

  it "resolves a successful selected block before critical and damage" do
    stub_percent_rolls(0, 99, 0) # hit, no dodge, block success

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
    stub_percent_rolls(0, 99, 99, 99) # hit, no dodge, block fail, no crit
    stub_base_hit_fraction(0.5)

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
    expect(result[:damage]).to be >= 1
  end

  it "does not invent a block-chance bonus from selector table identity" do
    stub_percent_rolls(0, 99, 0, 0, 99, 0)

    normal = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso",
      block: {"action_key" => "torso_block", "body_parts" => ["torso"], "block_table" => "normal"}
    )
    shield = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso",
      block: {
        "action_key" => "shield_90_head_torso_stomach_block",
        "body_parts" => ["torso"],
        "block_table" => "shield_90"
      }
    )

    expect(shield[:block_chance]).to eq(normal[:block_chance])
  end

  it "marks critical hits and applies ×2 before armor" do
    allow(attacker).to receive(:stats).and_return(Game::Systems::StatBlock.new(base: {
      strength: 1, dexterity: 10, luck: 20, vitality: 1, intelligence: 1
    }))
    allow(attacker).to receive(:attack_power).and_return(100)
    allow(defender).to receive(:defense).and_return(10)
    # crit_chance = 20*1.8 + 10*0.3 = 39 → roll 0 crits
    stub_percent_rolls(0, 99, 0)
    stub_base_hit_fraction(0.0) # min band: 100*0.6 = 60 → crit 120 → armor 110

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :hit, critical: true)
    expect(result[:crit_chance]).to eq(39.0)
    expect(result[:damage]).to eq(110)
    expect(described_class::CRITICAL_MULTIPLIER).to eq(2.0)
  end

  it "floors confirmed physical hits to at least min_damage after full defense" do
    stub_percent_rolls(0, 99, 99)
    stub_base_hit_fraction(0.0)
    allow(attacker).to receive(:attack_power).and_return(10)
    allow(defender).to receive(:defense).and_return(500)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :hit)
    expect(result[:damage]).to eq(described_class.resolution_table.fetch("min_damage").to_i)
  end

  it "computes crit_chance from luck and dexterity only (clamped)" do
    allow(attacker).to receive(:stats).and_return(Game::Systems::StatBlock.new(base: {
      strength: 1, dexterity: 0, luck: 0, vitality: 1, intelligence: 1
    }))
    allow(attacker).to receive(:critical_chance).and_return(50)
    stub_percent_rolls(0, 99, 99)
    stub_base_hit_fraction(0.5)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    # (0*1.8 + 0*0.3).clamp(5, 75) => 5.0
    expect(result[:crit_chance]).to eq(5.0)
  end

  it "uses magic_power and elemental resistance for mana attacks" do
    stub_percent_rolls(0, 99, 99)
    stub_base_hit_fraction(0.5)
    allow(attacker).to receive(:magic_power).and_return(40)
    allow(attacker).to receive(:attack_power).and_return(1)
    allow(defender).to receive(:defense).and_return(10)
    allow(defender).to receive(:elemental_resistance_percent).with("fire").and_return(20)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "veil_ember",
      body_part: "torso"
    )

    expect(result).to include(outcome: :hit)
    expect(result[:damage]).to be >= 1
  end

  it "rolls base_hit strictly inside attack_power * 0.6 .. 1.3 before armor" do
    allow(attacker).to receive(:attack_power).and_return(100)
    allow(defender).to receive(:defense).and_return(0)
    stub_percent_rolls(0, 99, 99)
    stub_base_hit_fraction(1.0) # max band

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result[:damage]).to eq(130)
  end
end
