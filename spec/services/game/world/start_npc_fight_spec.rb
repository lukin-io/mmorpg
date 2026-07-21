# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::StartNpcFight do
  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character, level: 4, current_hp: 100, max_hp: 100) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:npc_template) do
    create(
      :npc_template,
      npc_key: "plague_rat_service",
      name: "Plague Rat",
      role: "hostile",
      metadata: {"health" => 40, "base_damage" => 4}
    )
  end
  let(:tile_npc) do
    create(
      :tile_npc,
      npc_template:,
      zone: zone.name,
      x: 5,
      y: 5,
      current_hp: 40,
      max_hp: 40
    )
  end

  it "starts the shared NPC combat flow" do
    match = described_class.new(character:, tile_npc:).call

    expect(match).to be_live
    expect(match.metadata).to include(
      "source" => "world_npc",
      "tile_npc_id" => tile_npc.id,
      "x" => 5,
      "y" => 5
    )
    expect(match.arena_participations.count).to eq(2)
  end

  it "rolls back the match and participants when combat startup fails" do
    allow_any_instance_of(Arena::CombatProcessor).to receive(:start_match).and_raise(StandardError, "startup failed")

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(StandardError, "startup failed")

    expect(ArenaMatch.count).to eq(0)
    expect(ArenaParticipation.count).to eq(0)
  end

  it "rejects an NPC on another cell" do
    tile_npc.update!(x: 6)

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /current cell/)
  end

  it "rejects a defeated NPC" do
    tile_npc.update!(defeated_at: Time.current, current_hp: 0)

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /unavailable/)
  end

  it "rejects a null NPC" do
    expect {
      described_class.new(character:, tile_npc: nil).call
    }.to raise_error(described_class::FightViolationError, /unavailable/)
  end

  it "rejects a non-hostile NPC" do
    allow(tile_npc).to receive(:hostile?).and_return(false)

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /not hostile/)
  end

  it "rejects missing combat health" do
    npc_template.update!(metadata: npc_template.metadata.merge("health" => 0))
    tile_npc.update!(current_hp: 0, max_hp: 0)

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /not documented/)
  end
end
