require "rails_helper"

RSpec.describe Achievements::GrantService do
  it "grants achievement once" do
    user = create(:user)
    achievement = create(:achievement)

    described_class.new(user:, achievement:).call(source: "spec")

    expect(user.achievement_grants.count).to eq(1)
  end
end
