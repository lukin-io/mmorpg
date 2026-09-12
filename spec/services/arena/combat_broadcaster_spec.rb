# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatBroadcaster do
  let(:match) { create(:arena_match, :live) }
  let(:character) { create(:character, current_hp: 80, max_hp: 100, current_mp: 30, max_mp: 50) }
  let!(:participation) { create(:arena_participation, arena_match: match, character: character, user: character.user, team: "a") }
  let(:template) { create(:item_template, :durable, stat_modifiers: {"hp" => 60, "mana" => 25}) }
  let!(:equipment) do
    create(:inventory_item, :equipped, inventory: character.inventory, item_template: template,
      properties: {"current_durability" => 10})
  end
  let(:publisher) { instance_double(Arena::RealtimePublisher) }
  let(:payloads) { [] }
  let(:broadcaster) { described_class.new(match, publisher: publisher) }

  before do
    allow(publisher).to receive(:publish) do |channel:, payload:|
      expect(channel).to eq(match.broadcast_channel)
      payloads << payload
      true
    end
  end

  it "publishes effective maxima and matching HP/MP percentages without refilling current vitals" do
    broadcaster.broadcast_vitals_update(character)

    expect(payloads.last).to include(
      type: "hp_update", character_id: character.id, match_id: match.id,
      current_hp: 80, max_hp: 160, current_mp: 30, max_mp: 75,
      hp_percent: 50.0, mp_percent: 40.0, is_dead: false
    )
    expect(character.reload.attributes).to include("current_hp" => 80, "max_hp" => 100, "current_mp" => 30, "max_mp" => 50)
  end

  it "uses effective player maxima in match-start snapshots while preserving captured NPC vitals" do
    npc = create(:arena_participation, :npc, arena_match: match, team: "b",
      metadata: {"current_hp" => 600, "max_hp" => 605, "current_mp" => 3, "max_mp" => 7})

    broadcaster.broadcast_match_started

    expect(payloads.last).to include(type: "match_start", participants: array_including(
      hash_including(character_id: character.id, current_hp: 80, max_hp: 160, current_mp: 30, max_mp: 75, is_npc: false),
      hash_including(character_id: "npc-participation-#{npc.id}", current_hp: 600, max_hp: 605, current_mp: 3, max_mp: 7, is_npc: true)
    ))
  end

  it "reads changed equipment and saved vitals on each new match snapshot" do
    broadcaster.broadcast_match_start
    Character.find(character.id).update!(current_hp: 60, current_mp: 15)
    equipment.update!(properties: {"current_durability" => 0})

    broadcaster.broadcast_match_start

    expect(payloads.last.fetch(:participants)).to include(
      hash_including(character_id: character.id, current_hp: 60, max_hp: 100, current_mp: 15, max_mp: 50)
    )
  end

  it "recalculates equipment bonuses for each vitals event even on the same Character instance" do
    broadcaster.broadcast_hp_update(participation, character)
    equipment.update!(equipped: false)
    broadcaster.broadcast_hp_update(participation, character)

    expect(payloads.last).to include(max_hp: 100, max_mp: 50, hp_percent: 80.0, mp_percent: 60.0)
  end

  it "reads each maximum once per vitals payload to keep denominators consistent" do
    expect(character).to receive(:effective_max_hp).once.and_return(160)
    expect(character).to receive(:effective_max_mp).once.and_return(75)

    broadcaster.broadcast_hp_update(participation, character)

    expect(payloads.last).to include(max_hp: 160, max_mp: 75, hp_percent: 50.0, mp_percent: 40.0)
  end

  it "reports zero percentages safely when both effective maxima are zero" do
    equipment.update!(equipped: false)
    character.update!(current_hp: 0, max_hp: 0, current_mp: 0, max_mp: 0)

    broadcaster.broadcast_hp_update(participation, character)

    expect(payloads.last).to include(max_hp: 0, max_mp: 0, hp_percent: 0, mp_percent: 0, is_dead: true)
  end

  it "does not revive a defeated participation when the Character has recovered HP" do
    participation.update!(result: :defeat)
    broadcaster.broadcast_hp_update(participation, character)
    expect(payloads.last).to include(current_hp: 0, hp_percent: 0, is_dead: true)
    expect(character.reload.current_hp).to eq(80)
  end
end
