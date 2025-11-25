require "rails_helper"

RSpec.describe Users::PublicProfile do
  it "builds a sanitized payload without exposing email" do
    user = create(:user, reputation_score: 250)
    guild = create(:guild, leader: user)
    create(:guild_membership, guild: guild, user: user, status: :active)
    plot = create(:housing_plot, user: user)
    achievement = create(:achievement, name: "Explorer")
    create(:achievement_grant, user: user, achievement: achievement, granted_at: 1.day.ago)

    payload = described_class.new(user: user).as_json

    expect(payload[:profile_name]).to eq(user.profile_name)
    expect(payload[:reputation]).to eq(250)
    expect(payload[:guild]).to include(name: guild.name)
    expect(payload[:housing].first).to include(location_key: plot.location_key)
    combat_showcase = payload[:achievements][:categories]["combat"].first
    expect(combat_showcase).to include(name: "Explorer")
    expect(payload.values.join).not_to include(user.email)
  end
end
