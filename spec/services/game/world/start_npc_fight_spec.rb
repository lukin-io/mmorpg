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
    expect(match.metadata["return_context"]).to eq("name" => "world")
  end

  it "revalidates an NPC deactivated after the caller loaded it" do
    stale_npc = tile_npc
    TileNpc.find(stale_npc.id).update!(active: false)

    expect {
      expect { described_class.new(character:, tile_npc: stale_npc).call }
        .to raise_error(described_class::FightViolationError, "NPC is unavailable.")
    }.not_to change(ArenaMatch, :count)
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "creates one participation per source-backed encounter member" do
    tile_npc.update!(metadata: {"encounter_count" => 2})

    match = described_class.new(
      character:,
      tile_npc:,
      return_context: "inventory"
    ).call

    expect(match).to be_team_battle
    expect(match.metadata).to include(
      "encounter_count" => 2,
      "return_context" => {"name" => "inventory"}
    )
    expect(match.arena_participations.players.count).to eq(1)
    expect(match.arena_participations.npcs.count).to eq(2)
    expect(match.arena_participations.npcs.pluck(Arel.sql("metadata->>'encounter_slot'"))).to contain_exactly("1", "2")
  end

  it "creates the selected mixed roster with captured level, HP, XP, and risk" do
    robber = create(
      :npc_template,
      npc_key: "wilderness_robber_service",
      name: "Robber Service",
      level: 8,
      metadata: {"health" => 270, "base_damage" => 5}
    )
    tile_npc.update!(metadata: {
      "encounter_rosters" => [
        {
          "key" => "single",
          "encounter_experience_reward" => 9,
          "trauma_percent" => 30,
          "members" => [{"npc_key" => npc_template.npc_key, "level" => 7, "hp" => 155}]
        },
        {
          "key" => "mixed",
          "encounter_experience_reward" => 56,
          "trauma_percent" => 80,
          "members" => [
            {"npc_key" => npc_template.npc_key, "level" => 8, "hp" => 185},
            {"npc_key" => robber.npc_key, "level" => 9, "hp" => 310}
          ]
        }
      ]
    })
    rng = instance_double(Random, rand: 1)

    match = described_class.new(character:, tile_npc:, rng:).call

    participants = match.arena_participations.npcs.order(Arel.sql("(metadata->>'encounter_slot')::integer"))
    expect(match).to be_team_battle
    expect(match.trauma_percent).to eq(80)
    expect(match.metadata).to include(
      "encounter_count" => 2,
      "encounter_roster_sample" => "mixed",
      "encounter_member_keys" => [npc_template.npc_key, robber.npc_key],
      "encounter_experience_reward" => 56,
      "repeatable_encounter_source" => true,
      "fight_timeout_seconds" => 300
    )
    expect(participants.map(&:npc_template)).to eq([npc_template, robber])
    expect(participants.map(&:participant_level)).to eq([8, 9])
    expect(participants.map(&:max_hp)).to eq([185, 310])
  end

  it "creates all ten distinct opponent slots at the authored roster capacity" do
    tile_npc.update!(metadata: {
      "encounter_rosters" => [
        {"key" => "capacity-boundary", "members" => Array.new(10) { {"npc_key" => npc_template.npc_key} }}
      ]
    })

    match = described_class.new(character:, tile_npc:).call

    expect(match).to be_live
    expect(match.metadata["encounter_count"]).to eq(10)
    expect(match.arena_participations.players.count).to eq(1)
    expect(match.arena_participations.npcs.count).to eq(10)
    expect(match.arena_participations.npcs.pluck(Arel.sql("metadata->>'encounter_slot'")))
      .to match_array((1..10).map(&:to_s))
  end

  it "does not let optional member metadata replace authoritative combat fields" do
    tile_npc.update!(metadata: {
      "encounter_rosters" => [
        {
          "key" => "protected",
          "members" => [
            {
              "npc_key" => npc_template.npc_key,
              "level" => 8,
              "hp" => 185,
              "metadata" => {
                "current_hp" => 1,
                "max_hp" => 1,
                "level" => 99,
                "tile_npc_id" => -1,
                "encounter_slot" => 7,
                "encounter_roster_sample" => "forged",
                "captured_note" => "retained"
              }
            }
          ]
        }
      ]
    })

    match = described_class.new(character:, tile_npc:).call
    participation = match.arena_participations.npcs.sole

    expect(participation.metadata).to include(
      "current_hp" => 185,
      "max_hp" => 185,
      "level" => 8,
      "tile_npc_id" => tile_npc.id,
      "encounter_slot" => 1,
      "encounter_roster_sample" => "protected",
      "captured_note" => "retained"
    )
  end

  it "copies the captured paired-rat XP and injected blocks into the match profile" do
    position.update!(x: 7, y: 7)
    source_metadata = Game::World::OutdoorNpcConfig
      .source_npc_for_tile(zone.name, 7, 7)
      .fetch(:metadata)
      .deep_stringify_keys
    tile_npc.update!(x: 7, y: 7, metadata: source_metadata)

    match = described_class.new(character:, tile_npc:).call

    expect(match.metadata).to include(
      "encounter_count" => 2,
      "encounter_experience_reward" => 35
    )
    expect(match.metadata.dig("combat_profile", "injected_attack_keys")).to eq(
      %w[spirit_arrow mind_blast]
    )
    expect(match.metadata.dig("combat_profile", "injected_block_keys")).to eq(
      %w[magic_shield rainbow_barrier crystal_sphere]
    )
    expect(match.metadata["fight_timeout_seconds"]).to eq(300)
  end

  it "returns the existing active fight on a duplicate start" do
    first_match = described_class.new(character:, tile_npc:).call

    expect {
      expect(described_class.new(character:, tile_npc:).call).to eq(first_match)
    }.not_to change(ArenaMatch, :count)
  end

  it "does not start a same-cell encounter while movement owns the character" do
    movement = create(:movement_command, :moving, character:, zone:)

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /Movement already in progress/)

    expect(ArenaMatch.count).to eq(0)
    expect(ArenaParticipation.count).to eq(0)
    expect(position.reload).to have_attributes(x: 5, y: 5)
    expect(movement.reload).to be_moving
  end

  it "allows a passive fight to supersede the current Look timer" do
    work = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {"local_action_ends_at" => 28.seconds.from_now.iso8601(6), "local_action_result" => "Nothing useful here."})

    match = described_class.new(character:, tile_npc:).call

    expect(match).to be_live
    expect(work.reload).to be_cancelled
    expect(position.reload).to have_attributes(x: 5, y: 5)
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

  it "rejects eleven persisted opponents without creating a partial fight" do
    tile_npc.update_columns(metadata: {"encounter_count" => 11})

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /size is not supported/)
    expect(ArenaMatch.count).to eq(0)
    expect(ArenaParticipation.count).to eq(0)
  end

  it "rolls back when a captured roster references a missing template" do
    tile_npc.update_columns(metadata: {
      "encounter_rosters" => [
        {"key" => "missing", "members" => [{"npc_key" => "removed-npc", "level" => 7, "hp" => 155}]}
      ]
    })

    expect {
      described_class.new(character:, tile_npc:).call
    }.to raise_error(described_class::FightViolationError, /removed-npc.*unavailable/)
    expect(ArenaMatch.count).to eq(0)
  end
end
