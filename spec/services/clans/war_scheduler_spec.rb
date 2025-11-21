require "rails_helper"

RSpec.describe Clans::WarScheduler do
  it "creates a scheduled war" do
    attacker = create(:clan)
    defender = create(:clan)
    scheduler = described_class.new(attacker:, defender:)

    war = scheduler.schedule!(territory_key: "castle", starts_at: 2.days.from_now)

    expect(war).to be_persisted
    expect(war.status).to eq("scheduled")
  end
end
