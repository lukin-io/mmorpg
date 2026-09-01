# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PassiveEncounterCheck do
  let(:now) { Time.zone.parse("2026-08-26 18:00:00") }
  let(:clock) { -> { now } }
  let(:rng) { instance_double(Random, rand: 17) }
  let(:zone) { create(:zone, name: "Passive Encounter Woods", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:npc) { create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5) }

  subject(:check) { described_class.new(character:, clock:, rng:).call }

  it "persists a server-owned random due time before starting combat" do
    expect(check).not_to be_interrupted
    expect(check.retry_after_ms).to eq(17_000)
    expect(ArenaMatch.count).to eq(0)
    expect(rng).to have_received(:rand).with(
      described_class::MIN_DELAY_SECONDS..described_class::MAX_DELAY_SECONDS
    )
    expect(character.reload.metadata.fetch(described_class::SCHEDULE_METADATA_KEY)).to include(
      "zone_id" => zone.id,
      "x" => 5,
      "y" => 5,
      "tile_npc_id" => npc.id,
      "due_at" => (now + 17.seconds).iso8601(6)
    )
  end

  it "preserves the due time across early retries and starts the shared fight only when due" do
    first = check
    early = described_class.new(
      character:,
      clock: -> { now + 5.seconds },
      rng: instance_double(Random)
    ).call

    expect(first.retry_after_ms).to eq(17_000)
    expect(early).not_to be_interrupted
    expect(early.retry_after_ms).to eq(12_000)
    expect(ArenaMatch.count).to eq(0)

    due = described_class.new(
      character:,
      clock: -> { now + 17.seconds },
      rng: instance_double(Random)
    ).call

    expect(due).to be_interrupted
    expect(due.match).to be_live
    expect(due.match.arena_participations.npcs.count).to eq(2)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
  end

  it "clears the origin schedule when the character steps off the hostile cell" do
    check
    position.update!(x: 6)

    result = described_class.new(character:, clock: -> { now + 1.second }, rng: instance_double(Random)).call

    expect(result).not_to be_interrupted
    expect(result.retry_after_ms).to eq(described_class::EMPTY_RECHECK_SECONDS * 1_000)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
    expect(npc.reload.x).to eq(5)
  end

  it "replaces the origin schedule with the destination cell's hostile" do
    check
    position.update!(x: 6)
    destination_npc = create(:tile_npc, zone: zone.name, x: 6, y: 5)
    second_rng = instance_double(Random, rand: 23)

    result = described_class.new(character:, clock: -> { now + 1.second }, rng: second_rng).call

    expect(result.retry_after_ms).to eq(23_000)
    expect(character.reload.metadata.fetch(described_class::SCHEDULE_METADATA_KEY)).to include(
      "x" => 6,
      "y" => 5,
      "tile_npc_id" => destination_npc.id
    )
  end

  it "clears a stale schedule when the cell has no live hostile" do
    check
    npc.update!(defeated_at: now, current_hp: 0)

    result = described_class.new(character:, clock:, rng: instance_double(Random)).call

    expect(result).not_to be_interrupted
    expect(result.retry_after_ms).to eq(described_class::EMPTY_RECHECK_SECONDS * 1_000)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
  end

  it "does not schedule a city encounter" do
    zone.update!(location_type: "city")

    expect(check).not_to be_interrupted
    expect(ArenaMatch.count).to eq(0)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
  end

  it "returns an existing active fight without scheduling another" do
    active_match = Game::World::StartNpcFight.new(character:, tile_npc: npc).call

    expect(check).to be_interrupted
    expect(check.match).to eq(active_match)
    expect(ArenaMatch.count).to eq(1)
  end

  it "replaces malformed persisted timing instead of attacking immediately" do
    character.update!(metadata: {
      described_class::SCHEDULE_METADATA_KEY => {
        "zone_id" => zone.id,
        "x" => 5,
        "y" => 5,
        "tile_npc_id" => npc.id,
        "due_at" => "not-a-time"
      }
    })

    expect(check).not_to be_interrupted
    expect(check.retry_after_ms).to eq(17_000)
    expect(ArenaMatch.count).to eq(0)
  end
end
