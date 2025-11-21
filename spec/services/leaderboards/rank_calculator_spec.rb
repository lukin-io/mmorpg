require "rails_helper"

RSpec.describe Leaderboards::RankCalculator do
  it "assigns ranks by score" do
    leaderboard = create(:leaderboard)
    entry1 = leaderboard.leaderboard_entries.create!(entity_type: "User", entity_id: 1, score: 50)
    entry2 = leaderboard.leaderboard_entries.create!(entity_type: "User", entity_id: 2, score: 100)

    described_class.new(leaderboard).recalculate!

    expect(entry2.reload.rank).to eq(1)
    expect(entry1.reload.rank).to eq(2)
  end
end
