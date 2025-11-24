require "rails_helper"

RSpec.describe Game::Combat::ArenaLadder do
  let(:battle) { create(:battle, battle_type: :arena) }
  let(:winner) { battle.initiator }
  let(:loser_participant) { create(:battle_participant, battle:, team: "bravo") }

  before do
    loser_participant.update!(character: create(:character))
  end

  it "adjusts ratings for winner and loser" do
    result = described_class.new(battle:).apply!(winner:)

    expect(result[:winner_rating]).to be > 1200
    expect(result[:loser_rating]).to be < 1200
  end

  context "when battle tracks a duel ladder" do
    let(:battle) { create(:battle, battle_type: :pvp, pvp_mode: "duel") }

    it "creates duel-specific ratings" do
      described_class.new(battle:).apply!(winner:)

      expect(winner.arena_rankings.for_ladder("duel").count).to eq(1)
    end
  end
end
