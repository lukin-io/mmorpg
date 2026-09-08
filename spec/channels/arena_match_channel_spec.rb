# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaMatchChannel, type: :channel do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:arena_room) { create(:arena_room) }
  let(:arena_match) do
    create(:arena_match, arena_room:, status: :live, started_at: Time.current)
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
      .with(character, "turn", target: target_npc, attacks:, blocks:)
      .and_return(result)

    perform :submit_action, {
      "action_type" => "turn",
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
end
