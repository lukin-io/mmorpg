# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatchChannel, type: :channel do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:arena_room) { create(:arena_room) }
  let(:arena_match) do
    create(:arena_match, arena_room:, status: :live, started_at: Time.current, current_turn_number: 1)
  end
  let!(:player_participation) do
    create(:arena_participation, arena_match:, character:, user:, team: "a")
  end
  let(:npc_template) { create(:npc_template, name: "Repeated Skeleton") }
  let!(:first_npc) do
    create(:arena_participation, :npc, arena_match:, npc_template:, team: "b")
  end
  let!(:target_npc) do
    create(:arena_participation, :npc, arena_match:, npc_template:, team: "b")
  end

  before do
    stub_connection(current_user: user)
    subscribe(match_id: arena_match.id)
  end

  it "submits a complete turn against one exact repeated NPC participation" do
    processor = instance_double(Arena::CombatProcessor)
    result = Arena::CombatProcessor::Result.new(true, nil, {waiting: false})
    attacks = [{"action_key" => "simple", "body_part" => "torso"}]
    blocks = [{"action_key" => "torso_block", "body_parts" => ["torso"]}]

    expect(Arena::CombatProcessor).to receive(:new).with(arena_match).and_return(processor)
    expect(processor).to receive(:process_player_intent)
      .with(character, "turn", target: target_npc, attacks:, blocks:, expected_turn_number: 1)
      .and_return(result)

    perform :submit_action, {
      "action_type" => "turn",
      "turn_number" => 1,
      "target_id" => "npc-participation-#{target_npc.id}",
      "attacks" => attacks,
      "blocks" => blocks
    }

    expect(transmissions.last).to include("type" => "action_result", "success" => true)
  end

  it "returns an authoritative reconnect snapshot with exact NPC participation ids" do
    arena_match.update!(current_turn_number: 3)

    perform :request_match_state

    snapshot = transmissions.last
    expect(snapshot).to include(
      "type" => "match_state",
      "status" => "live",
      "current_turn_number" => 3,
      "current_user_waiting" => false
    )
    expect(snapshot.fetch("participants")).to include(
      hash_including("character_id" => "npc-participation-#{target_npc.id}")
    )
  end

  it "returns equipment-aware maxima and current vitals on reconnect without refilling the character" do
    character.update!(current_hp: 80, max_hp: 100, current_mp: 30, max_mp: 50)
    template = create(:item_template, :durable, stat_modifiers: {"hp" => 60, "mana" => 25})
    item = create(:inventory_item, :equipped, inventory: character.inventory, item_template: template,
      properties: {"current_durability" => 10})
    target_npc.update!(metadata: {"current_hp" => 600, "max_hp" => 605, "current_mp" => 3, "max_mp" => 7})

    perform :request_match_state

    expect(transmissions.last.fetch("participants")).to include(
      hash_including("character_id" => character.id, "current_hp" => 80, "max_hp" => 160, "current_mp" => 30, "max_mp" => 75),
      hash_including("character_id" => "npc-participation-#{target_npc.id}", "current_hp" => 600, "max_hp" => 605, "current_mp" => 3, "max_mp" => 7)
    )
    expect(character.reload.attributes).to include("current_hp" => 80, "max_hp" => 100, "current_mp" => 30, "max_mp" => 50)

    # A later callback must reread both saved vitals and equipment state.
    Character.find(character.id).update!(current_hp: 60, current_mp: 15)
    item.update!(properties: {"current_durability" => 0})
    perform :request_match_state

    expect(transmissions.last.fetch("participants")).to include(
      hash_including("character_id" => character.id, "current_hp" => 60, "max_hp" => 100, "current_mp" => 15, "max_mp" => 50)
    )
  end

  it "keeps recovered defeated players and NPCs dead on reconnect without resetting their recovered resources" do
    character.update!(current_hp: 80)
    player_participation.update!(result: :defeat, metadata: {"pending_turn" => {"turn_number" => 1}})
    first_npc.update!(result: :defeat, metadata: {"current_hp" => 50, "max_hp" => 100})

    perform :request_match_state

    expect(transmissions.last).to include("current_user_waiting" => false)
    expect(transmissions.last.fetch("participants")).to include(
      hash_including("character_id" => character.id, "current_hp" => 0, "is_dead" => true),
      hash_including("character_id" => "npc-participation-#{first_npc.id}", "current_hp" => 0, "is_dead" => true),
      hash_including("character_id" => "npc-participation-#{target_npc.id}", "current_hp" => 100, "is_dead" => false)
    )
    expect(character.reload.current_hp).to eq(80)
    expect(first_npc.reload.current_hp).to eq(50)
  end

  context "with the real combat processor" do
    let(:packet) do
      {
        "action_type" => "turn", "turn_number" => 1,
        "target_id" => "npc-participation-#{first_npc.id}",
        "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
        "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}]
      }
    end

    before do
      create(:character_position, character: character)
      # Fix damage only; the channel, processor, locks, AP, round advancement,
      # persisted vitals and stale-turn rejection all execute normally.
      resolver = instance_double(Arena::CombatResolver,
        resolve_physical_attack: {outcome: :hit, damage: 1, critical: false})
      allow(Arena::CombatResolver).to receive(:new).and_return(resolver)
    end

    def authoritative_turn_state
      [arena_match.reload.current_turn_number, character.reload.current_hp, character.current_mp,
        first_npc.reload.current_hp, target_npc.reload.current_hp,
        player_participation.reload.metadata, arena_match.combat_log_entries.count]
    end

    it "rejects a missing turn number without resolving an action" do
      original = authoritative_turn_state
      perform :submit_action, packet.except("turn_number")
      expect(transmissions.last).to include("type" => "action_result", "success" => false)
      expect(authoritative_turn_state).to eq(original)
    end

    [nil, "bad", "1.5", 1.0, 0, -1, true, [1]].each do |invalid|
      it "rejects malformed/nonpositive turn #{invalid.inspect} without changing authoritative state" do
        original = authoritative_turn_state
        perform :submit_action, packet.merge("turn_number" => invalid)
        expect(transmissions.last).to include("type" => "action_result", "success" => false)
        expect(authoritative_turn_state).to eq(original)
      end
    end

    it "rejects a stale turn rather than substituting the current server round" do
      arena_match.update!(current_turn_number: 3)
      original = authoritative_turn_state
      perform :submit_action, packet
      expect(transmissions.last).to include("type" => "action_result", "success" => false)
      expect(authoritative_turn_state).to eq(original)
    end

    it "advances consecutive rounds once each and rejects replay across reconnect snapshots" do
      perform :submit_action, packet
      expect(transmissions.last).to include("success" => true)
      expect(arena_match.reload.current_turn_number).to eq(2)
      expect(first_npc.reload.current_hp).to eq(99)
      expect(player_participation.reload.metadata["last_resolved_turn_number"]).to eq(1)
      original = authoritative_turn_state

      perform :request_match_state
      expect(transmissions.last["current_turn_number"]).to eq(2)
      perform :submit_action, packet
      expect(transmissions.last).to include("success" => false)
      expect(authoritative_turn_state).to eq(original)

      perform :submit_action, packet.merge("turn_number" => "2")
      expect(transmissions.last).to include("success" => true)
      expect(arena_match.reload.current_turn_number).to eq(3)
      expect(first_npc.reload.current_hp).to eq(98)
      expect(player_participation.reload.metadata["last_resolved_turn_number"]).to eq(2)
      original = authoritative_turn_state

      [1, 2].each do |old_round|
        perform :submit_action, packet.merge("turn_number" => old_round)
        expect(transmissions.last).to include("success" => false)
        expect(authoritative_turn_state).to eq(original)
      end
    end

    it "allows surrender without a turn number" do
      perform :submit_action, {"action_type" => "surrender"}
      expect(transmissions.last).to include("success" => true)
      expect(arena_match.reload).to be_completed
      expect(player_participation.reload).to be_defeat
    end
  end
end
