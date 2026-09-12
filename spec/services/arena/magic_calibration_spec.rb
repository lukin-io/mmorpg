# frozen_string_literal: true

require "rails_helper"
RSpec.describe Arena::CombatResolver, "captured magic" do
  let(:match) { create(:arena_match, :live) }
  let(:attacker) { create(:arena_participation, arena_match: match, team: "a") }
  let(:defender) { create(:arena_participation, arena_match: match, team: "b") }
  let(:rng) { instance_double(Random, rand: 0) }
  let(:resolver) { described_class.new(match:, rng:) }
  def cast(block: nil)
    resolver.resolve_physical_attack(attacker_participation: attacker, defender_participation: defender,
      action_key: "spirit_arrow", body_part: "torso", block:)
  end

  it "reproduces the 5-MP Spirit Arrow critical for 10 independently of physical armor" do
    armor = create(:item_template, stat_modifiers: {"armor_class" => 1000})
    create(:inventory_item, :equipped, inventory: defender.character.inventory, item_template: armor)
    expect(cast).to include(damage: 10, critical: true, element: "arcane")
  end

  it "applies only a committed magical barrier's reduction and no expired/inactive defense" do
    expect(cast(block: {"block_table" => "magic", "action_key" => "magic_shield"})[:damage]).to eq(8)
    expect(cast(block: {"block_table" => "magic", "action_key" => "crystal_sphere"})[:damage]).to eq(4)
    expect(cast[:damage]).to eq(10)
  end
end
