# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcExperienceAwarder, "explicit defeat XP" do
  let(:match) do
    create(:arena_match, :live, metadata: {
      "source" => "world_npc", "is_npc_fight" => true,
      "encounter_experience_reward" => 5000, "encounter_defeat_experience_reward" => 57
    })
  end
  let(:player) { create(:character, level: 17, current_hp: 0) }
  let!(:player_side) do
    create(:arena_participation, arena_match: match, character: player, user: player.user,
      team: "a", result: :defeat, metadata: {"damage_dealt" => 605, "opponents_defeated" => 1})
  end
  let!(:defeated_npc) do
    create(:arena_participation, :npc, arena_match: match, team: "b", result: :defeat,
      metadata: {"current_hp" => 0, "max_hp" => 605})
  end
  let!(:surviving_npcs) do
    Array.new(2) { create(:arena_participation, :npc, arena_match: match, team: "b", result: :victory) }
  end

  def award(winning_team: "b")
    described_class.new(match: match, winning_team: winning_team).call
  end

  def expect_no_xp(result)
    expect(result.character_id).to be_nil
    expect(result.experience_awarded).to eq(0)
    expect(player.reload.experience).to eq(0)
  end

  it "awards the explicitly captured 57 XP to the losing player, never the NPC winner" do
    expect(award).to have_attributes(character_id: player.id, experience_awarded: 57, levels_gained: 0, skipped_reason: nil)
    expect(player.reload.experience).to eq(57)
  end

  [nil, 0, -1, 57.5, "57", "unknown", {}, [], true].each do |value|
    it "does not reuse victory or NPC rewards for missing/invalid defeat XP #{value.inspect}" do
      match.update!(metadata: match.metadata.merge("encounter_defeat_experience_reward" => value))
      defeated_npc.npc_template.update!(metadata: {"xp_reward" => 5000})
      expect_no_xp(award)
    end
  end

  it "requires an actually defeated enemy NPC, not damage or a player-supplied kill counter" do
    defeated_npc.update!(result: :victory, metadata: {"current_hp" => 100})
    expect_no_xp(award)
  end

  it "does not count defeated allied NPCs" do
    defeated_npc.update!(team: "a")
    expect_no_xp(award)
  end

  it "does not grant configured defeat XP on a draw" do
    expect_no_xp(award(winning_team: nil))
  end

  it "requires the winning side to contain an enemy NPC" do
    expect_no_xp(award(winning_team: "other"))
  end

  it "awards a calibrated contribution share to a defeated player group" do
    defeated_npc.update!(metadata: defeated_npc.metadata.merge("level" => 13))
    teammate = create(:character, level: 17, current_hp: 0)
    create(:arena_participation, arena_match: match, character: teammate, user: teammate.user, team: "a", result: :defeat)
    expect(award.experience_awarded).to be_positive
    expect(teammate.reload.experience).to be_positive
  end

  it "ignores the defeat field when awarding a victory without an explicit victory total" do
    match.update!(metadata: match.metadata.except("encounter_experience_reward"))
    surviving_npcs.each(&:destroy!)
    defeated_npc.npc_template.update!(metadata: {"xp_reward" => 35})
    player_side.update!(result: :victory)

    expect(award(winning_team: "a").experience_awarded).to eq(35)
    expect(player.reload.experience).to eq(35)
  end

  it "applies the current entitlement cap to an explicit defeat total" do
    player.update!(metadata: {"combat_entitlement" => {"tier" => "gold", "expires_at" => 1.hour.from_now.iso8601}})
    match.update!(metadata: match.metadata.merge("encounter_defeat_experience_reward" => 500_000))
    expect(award.experience_awarded).to eq(200_000)
    expect(player.reload.experience).to eq(200_000)
  end

  it "preserves the unsupported-level zero cap even for configured defeat XP" do
    player.update!(level: 28)
    expect_no_xp(award)
  end
end
