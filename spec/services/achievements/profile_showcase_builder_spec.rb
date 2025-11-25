require "rails_helper"

RSpec.describe Achievements::ProfileShowcaseBuilder do
  it "groups achievements per category and lists equipped titles" do
    user = create(:user)
    achievement = create(:achievement, category: "combat", points: 50)
    Achievements::GrantService.new(user:, achievement:).call(source: "spec")
    title = create(:title)
    user.title_grants.create!(title:, source: "manual", granted_at: Time.current, equipped: true)

    result = described_class.new(user:).call

    expect(result[:categories]["combat"].first[:name]).to eq(achievement.name)
    expect(result[:titles].first[:name]).to eq(title.name)
  end
end
