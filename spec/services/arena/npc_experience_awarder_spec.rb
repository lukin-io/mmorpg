# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcExperienceAwarder do
  let(:match) { create(:arena_match, :live, metadata: {"source" => "world_npc", "is_npc_fight" => true}) }
  let(:winner) { create(:character, :neverlands_starter, level: 10) }

  before do
    create(:arena_participation, arena_match: match, character: winner, user: winner.user, team: "a", result: :victory)
  end

  it "uses the captured total reward for the whole paired-rat encounter" do
    match.update!(metadata: match.metadata.merge("encounter_experience_reward" => 35))
    [35, 35].each_with_index do |xp, index|
      npc = create(:npc_template, npc_key: "rat_#{index}", metadata: {"xp_reward" => xp})
      create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b", result: :defeat)
    end

    result = described_class.new(match:, winning_team: "a").call

    expect(result).to have_attributes(character_id: winner.id, experience_awarded: 35, levels_gained: 0, skipped_reason: nil)
    expect(winner.reload.experience).to eq(35)
  end

  it "sums Ashen level-delta XP across defeated NPCs and applies the fight cap" do
    2.times do |index|
      npc = create(:npc_template, level: 10, npc_key: "pack_#{index}", metadata: {})
      create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b", result: :defeat)
    end

    result = described_class.new(match:, winning_team: "a").call

    # 2 × (10*15) = 300, fight_experience_cap(10) = 292
    expect(result).to have_attributes(experience_awarded: 292, skipped_reason: nil)
    expect(winner.reload.experience).to eq(292)
  end

  it "splits group XP by damage dealt among winning players" do
    teammate = create(:character, :neverlands_starter, level: 10)
    create(:arena_participation, arena_match: match, character: teammate, user: teammate.user, team: "a", result: :victory,
      metadata: {"damage_dealt" => 30})
    match.arena_participations.players.find_by(character: winner).update!(metadata: {"damage_dealt" => 70})
    npc = create(:npc_template, level: 10, metadata: {})
    create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b", result: :defeat)

    result = described_class.new(match:, winning_team: "a").call

    expect(result.skipped_reason).to be_nil
    expect(result.party_awards.size).to eq(2)
    # pool 150 × 0.7 / 0.3
    expect(winner.reload.experience).to eq(105)
    expect(teammate.reload.experience).to eq(45)
  end

  it "awards nothing for a draw" do
    expect(described_class.new(match:, winning_team: nil).call.skipped_reason).to eq("draw")
  end

  it "still awards level-scaled XP when metadata omits xp_reward" do
    no_meta_npc = create(:npc_template, level: 1, metadata: {})
    create(:arena_participation, :npc, arena_match: match, npc_template: no_meta_npc, team: "b", result: :defeat)

    result = described_class.new(match:, winning_team: "a").call

    expect(result.skipped_reason).to be_nil
    expect(result.experience_awarded).to eq(2)
  end
end
