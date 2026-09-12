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

  it "preserves a critical attempt that is dodged without rolling damage" do
    allow(rng).to receive(:rand).with(100).and_return(0, 0)

    result = resolver.resolve_physical_attack(
      attacker_participation:,
      defender_participation:,
      action_key: "simple",
      body_part: "torso"
    )

    expect(result).to include(outcome: :dodge, dodge: true, critical: true, damage: 0)
    expect(result[:crit_chance]).to be_positive
    expect(rng).not_to have_received(:rand).with(1..5)
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

  it "does not invent a block-chance bonus from selector table identity" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 0, 0, 99, 0)

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

  it "uses equipped player Accuracy and Evasion in the shared outcome probabilities" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 99, 0, 99, 99)
    allow(rng).to receive(:rand).with(1..5).and_return(3)
    baseline = resolver.resolve_physical_attack(
      attacker_participation:, defender_participation:, action_key: "simple", body_part: "torso"
    )
    item = create(:item_template, slot: "amulet", stat_modifiers: {"accuracy" => -30, "evasion" => 30})
    create(:inventory_item, :equipped, inventory: attacker.inventory, item_template: item)
    create(:inventory_item, :equipped, inventory: defender.inventory, item_template: item)
    attacker.reload
    defender.reload
    changed = resolver.resolve_physical_attack(
      attacker_participation:, defender_participation:, action_key: "simple", body_part: "torso"
    )

    expect(changed[:hit_chance]).to be < baseline[:hit_chance]
    expect(changed[:dodge_chance]).to be > baseline[:dodge_chance]
  end

  it "gives captured NPC Dexterity the same defensive meaning as legacy agility" do
    allow(rng).to receive(:rand).with(100).and_return(0, 99, 99, 0, 99, 99)
    allow(rng).to receive(:rand).with(1..5).and_return(3)
    npc = create(:npc_template, metadata: {"stats" => {"dexterity" => 40}})
    npc_side = create(:arena_participation, :npc, arena_match:, npc_template: npc, team: "b")
    dexterity_result = resolver.resolve_physical_attack(
      attacker_participation:, defender_participation: npc_side, action_key: "simple", body_part: "torso"
    )
    npc_side.update!(metadata: {"stats" => {"dexterity" => 0, "agility" => 40}})
    agility_result = resolver.resolve_physical_attack(
      attacker_participation:, defender_participation: npc_side, action_key: "simple", body_part: "torso"
    )

    expect(dexterity_result[:hit_chance]).to eq(agility_result[:hit_chance])
    expect(dexterity_result[:dodge_chance]).to eq(agility_result[:dodge_chance])
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
    expect(described_class::CRITICAL_MULTIPLIER).to eq(2.0)
  end
end
