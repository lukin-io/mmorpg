# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PassiveEncounterCheck do
  let(:now) { Time.zone.parse("2026-08-26 18:00:00") }
  let(:clock) { -> { now } }
  let(:rng) { instance_double(Random, rand: 17) }
  let(:zone) { create(:zone, name: "Passive Encounter Woods", location_type: "outdoor") }
  let(:character) { create(:character, level: 4) }
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

  it "samples only inside captured delay windows for the exact cell" do
    npc.update!(metadata: npc.metadata.merge(
      "passive_delay_windows" => [
        {"key" => "long", "min_seconds" => 230, "max_seconds" => 278},
        {"key" => "short", "min_seconds" => 127, "max_seconds" => 187}
      ]
    ))
    source_rng = instance_double(Random)
    expect(source_rng).to receive(:rand).with(2).and_return(1)
    expect(source_rng).to receive(:rand).with(127..187).and_return(154)

    result = described_class.new(character:, clock:, rng: source_rng).call

    expect(result).not_to be_interrupted
    expect(result.retry_after_ms).to eq(154_000)
    expect(character.reload.metadata.fetch(described_class::SCHEDULE_METADATA_KEY)).to include(
      "due_at" => (now + 154.seconds).iso8601(6)
    )
  end

  it "does not resample a captured delay window on an early retry" do
    npc.update!(metadata: npc.metadata.merge(
      "passive_delay_windows" => [{"key" => "observed", "min_seconds" => 127, "max_seconds" => 187}]
    ))
    source_rng = instance_double(Random, rand: 150)
    described_class.new(character:, clock:, rng: source_rng).call
    retry_rng = instance_double(Random)

    result = described_class.new(character:, clock: -> { now + 25.seconds }, rng: retry_rng).call

    expect(result.retry_after_ms).to eq(125_000)
  end

  it "honors the starter profile's user-reported interval, reuses early retries and starts one repeatable fight at its deadline" do
    definition = Game::World::OutdoorNpcConfig.config.fetch(:outpost_surroundings)
      .fetch(:starter_npcs).find { |entry| entry.values_at(:x, :y) == [0, 3] }
    template = create(:npc_template, npc_key: "wilderness_bandit", level: 7, metadata: {"health" => 155})
    npc.update!(npc_template: template, npc_key: "wilderness_bandit", level: 7, max_hp: 155, current_hp: 155,
      metadata: definition.fetch(:metadata).deep_stringify_keys)
    interval_rng = instance_double(Random)
    expect(interval_rng).to receive(:rand).with(300..360).once.and_return(300)

    initial = described_class.new(character:, clock:, rng: interval_rng).call
    expect(initial.retry_after_ms).to eq(300_000)
    early = described_class.new(character:, clock: -> { now + 299.seconds }, rng: instance_double(Random)).call
    expect(early.retry_after_ms).to eq(1_000)
    expect(ArenaMatch.count).to eq(0)

    selection_rng = instance_double(Random)
    expect(selection_rng).to receive(:rand).with(2).once.and_return(0)
    due = described_class.new(character:, clock: -> { now + 300.seconds }, rng: selection_rng).call
    expect(due).to be_interrupted
    expect(due.message).to eq("A fight starts while you wait.")
    expect(due.match.metadata).to include("repeatable_encounter_source" => true, "encounter_roster_sample" => "2026-09-01-2340")
    expect(due.match.arena_participations.npcs.sole).to have_attributes(max_hp: 155, participant_level: 7)

    duplicate = described_class.new(character:, clock: -> { now + 300.seconds }, rng: instance_double(Random)).call
    expect(duplicate.match).to eq(due.match)
    expect(ArenaMatch.count).to eq(1)
    expect(npc.reload).to be_alive
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
    expect(due.message).to eq("A fight starts while you wait.")
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

  it "clears a due source-cell schedule while timed movement is active" do
    check
    movement = create(:movement_command, :moving, character:, zone:)

    result = described_class.new(character:, clock: -> { now + 30.seconds }, rng: instance_double(Random)).call

    expect(result).not_to be_interrupted
    expect(result.retry_after_ms).to eq(described_class::EMPTY_RECHECK_SECONDS * 1_000)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
    expect(movement.reload).to be_moving
    expect(ArenaMatch.count).to eq(0)
  end

  it "completes due travel before checking for a passive encounter at the destination" do
    check
    movement = create(:movement_command, :moving, character:, zone:, ends_at: 1.second.ago)

    result = described_class.new(character:, clock: -> { now + 30.seconds }, rng: instance_double(Random)).call

    expect(result).not_to be_interrupted
    expect(movement.reload).to be_completed
    expect(position.reload).to have_attributes(x: 5, y: 4)
    expect(character.reload.metadata).not_to have_key(described_class::SCHEDULE_METADATA_KEY)
    expect(ArenaMatch.count).to eq(0)
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
