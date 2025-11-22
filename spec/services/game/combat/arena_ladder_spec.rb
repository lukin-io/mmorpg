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
end
