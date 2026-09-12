# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcExperienceAwarder do
  let(:match) { create(:arena_match, :live, metadata: {"source" => "world_npc", "is_npc_fight" => true}) }
  let(:winner) { create(:character, :neverlands_starter) }

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

  it "calculates and caps a non-authored multi-NPC encounter" do
    2.times do |index|
      npc = create(:npc_template, npc_key: "uncaptured_#{index}", metadata: {"xp_reward" => 35})
      create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b", result: :defeat)
    end

    result = described_class.new(match:, winning_team: "a").call

    expect(result.experience_awarded).to be_positive
    expect(winner.reload.experience).to eq(result.experience_awarded)
  end

  it "shares configured single-NPC XP between player participants" do
    teammate = create(:character)
    create(:arena_participation, arena_match: match, character: teammate, user: teammate.user, team: "a", result: :victory)
    npc = create(:npc_template, metadata: {"xp_reward" => 35})
    create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b", result: :defeat)

    result = described_class.new(match:, winning_team: "a").call

    expect(result.experience_awarded).to be_positive
    expect(winner.reload.experience).to eq(result.experience_awarded)
    expect(teammate.reload.experience).to eq(17)
  end

  it "awards nothing on a draw and derives XP when no explicit reward exists" do
    no_xp_npc = create(:npc_template, metadata: {})
    create(:arena_participation, :npc, arena_match: match, npc_template: no_xp_npc, team: "b", result: :defeat)

    expect(described_class.new(match:, winning_team: nil).call.skipped_reason).to eq("draw")
    expect(described_class.new(match:, winning_team: "a").call.experience_awarded).to be_positive
  end
end
