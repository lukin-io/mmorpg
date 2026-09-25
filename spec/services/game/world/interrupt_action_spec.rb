# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::InterruptAction do
  let(:zone) { create(:zone, name: "Encounter Woods", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  subject(:result) { described_class.new(character:, return_context: "world").call }

  it "replaces an outdoor action with a same-cell hostile encounter when bait is present" do
    npc = create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)
    grant_bait!(character)

    expect(result).to be_interrupted
    expect(result.npc).to eq(npc)
    expect(result.match.arena_participations.npcs.count).to eq(2)
    expect(result.match.metadata["return_context"]).to eq("name" => "world")
    expect(Game::World::Bait.new(character:).quantity).to eq(0)
  end

  it "does not interrupt without bait even when a hostile is present" do
    create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)

    expect(result).not_to be_interrupted
    expect(result.hint).to include("5")
    expect(ArenaMatch.count).to eq(0)
  end

  it "does not interrupt without a source-backed hostile NPC" do
    grant_bait!(character)
    expect(result).not_to be_interrupted
    expect(result.match).to be_nil
  end

  it "does not interrupt city actions" do
    zone.update!(location_type: "city")
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    expect(result).not_to be_interrupted
  end

  it "returns the active fight without creating another one" do
    npc = create(:tile_npc, zone: zone.name, x: 5, y: 5)
    active_match = Game::World::StartNpcFight.new(character:, tile_npc: npc).call

    expect { result }.not_to change(ArenaMatch, :count)
    expect(result).to be_interrupted
    expect(result.match).to eq(active_match)
  end

  it "ignores a defeated hostile encounter anchor" do
    create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5)

    expect(result).not_to be_interrupted
  end

  it "rejects world actions during travel without starting a same-cell fight" do
    create(:tile_npc, zone: zone.name, x: 5, y: 5)
    movement = create(:movement_command, :moving, character:, zone:)

    expect { result }.to raise_error(Game::World::StartNpcFight::FightViolationError, I18n.t("game.flashes.movement_in_progress"))

    expect(ArenaMatch.count).to eq(0)
    expect(movement.reload).to be_moving
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "finishes due travel before resolving the hostile cell for a world action" do
    create(:tile_npc, zone: zone.name, x: 5, y: 5)
    movement = create(:movement_command, :moving, character:, zone:, ends_at: 1.second.ago)

    expect(result).not_to be_interrupted

    expect(movement.reload).to be_completed
    expect(position.reload).to have_attributes(x: 5, y: 4)
    expect(ArenaMatch.count).to eq(0)
  end

  it "rejects world actions while the persisted Look timer is active" do
    work = create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {"local_action_ends_at" => 28.seconds.from_now.iso8601(6), "local_action_result" => "Nothing useful here."})
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    expect { result }.to raise_error(Game::World::StartNpcFight::FightViolationError, I18n.t("game.world.local_action_in_progress"))

    expect(work.reload).to be_accepted
    expect(ArenaMatch.count).to eq(0)
  end

  it "lets Character and Inventory open without bait fights even on a hostile cell" do
    create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)
    grant_bait!(character)

    %w[profile inventory].each do |context|
      outcome = described_class.new(character:, return_context: context).call
      expect(outcome).not_to be_interrupted
    end

    hash_outcome = described_class.new(
      character:,
      return_context: {"name" => "inventory"}
    ).call
    expect(hash_outcome).not_to be_interrupted
    expect(ArenaMatch.count).to eq(0)
    expect(Game::World::Bait.new(character:).quantity).to eq(1)
  end

  it "lets Character and Inventory open during travel and Look timers" do
    create(:movement_command, :moving, character:, zone:)
    create(:world_action_offer, character:, zone:, x: 5, y: 5,
      action_type: "search_resources", status: :accepted, accepted_at: Time.current,
      metadata: {
        "local_action_ends_at" => 28.seconds.from_now.iso8601(6),
        "local_action_result" => "Nothing useful here."
      })

    expect(described_class.new(character:, return_context: "inventory").call).not_to be_interrupted
    expect(
      described_class.new(character:, return_context: {"name" => "profile"}).call
    ).not_to be_interrupted
  end
end
