# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::ExperienceAwarder, "player opponents" do
  let(:match) { create(:arena_match, :live, trauma_percent: 30, metadata: {physical_only: true}) }
  let(:winner) { create(:character, level: 10, max_hp: 1_000, current_hp: 1_000) }
  let(:loser) { create(:character, level: 10, max_hp: 1_000, current_hp: 0) }
  let!(:a) { create(:arena_participation, arena_match: match, character: winner, user: winner.user, team: "a", result: :victory, metadata: {damage_dealt: 1_000}) }
  let!(:b) { create(:arena_participation, arena_match: match, character: loser, user: loser.user, team: "b", result: :defeat, metadata: {damage_taken: 1_000}) }

  it "uses credited HP, level and trauma with the existing recipient cap" do
    result = described_class.new(match:, winning_team: "a").call_all.find { |award| award.character_id == winner.id }
    config = Game::Combat::Calibration.config.fetch("experience")
    expected = (1_000 * config.fetch("hp_rate") * config.fetch("pvp_trauma_multiplier").fetch("30")).round
    expect(result.experience_awarded).to eq([expected, Game::Progression::Catalog.fight_experience_cap(10)].min)
    expect(winner.reload.experience).to eq(result.experience_awarded)
    expect(loser.reload.experience).to eq(0)
  end

  it "awards a defeated PvP contributor even when the enemy survives" do
    winner.update!(level: 24)
    loser.update!(level: 17)
    a.update!(metadata: {damage_dealt: 1_000, damage_taken: 194})
    b.update!(metadata: {damage_dealt: 194, damage_taken: 1_000})
    awards = described_class.new(match:, winning_team: "a").call_all
    loss = awards.find { |entry| entry.character_id == loser.id }
    # Source sample is177; v1's retained HP/risk coefficients approximate181.
    expect(loss.experience_awarded).to eq(181)
    expect(loser.reload.experience).to eq(181)
  end

  it "gives no XP for an untouched surrender or a draw" do
    b.update!(metadata: {damage_taken: 0})
    described_class.new(match:, winning_team: "a").call_all
    expect(winner.reload.experience).to eq(0)
    expect(described_class.new(match:, winning_team: nil).call.skipped_reason).to eq("draw")
  end

  it "shares a team reward with a defeated contributing ally, excluding overkill credit" do
    ally = create(:character, level: 10)
    create(:arena_participation, arena_match: match, character: ally, user: ally.user, team: "a", result: :defeat, metadata: {damage_dealt: 250})
    a.update!(metadata: {damage_dealt: 750})
    b.update!(metadata: {damage_taken: 50_000})
    awards = described_class.new(match:, winning_team: "a").call_all
    winner_award = awards.find { |entry| entry.character_id == winner.id }
    ally_award = awards.find { |entry| entry.character_id == ally.id }
    expect(ally_award.experience_awarded).to be_positive
    expect(winner_award.experience_awarded).to be > ally_award.experience_awarded
    expect(winner_award.experience_awarded + ally_award.experience_awarded).to be <= 990
  end
end
