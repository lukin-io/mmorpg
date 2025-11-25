require "rails_helper"

RSpec.describe Party do
  it "boots with leader membership and chat channel" do
    leader = create(:user)

    party = described_class.create!(name: "Alpha Squad", purpose: "Dungeon run", leader: leader)

    expect(party.chat_channel).to be_present
    expect(party.chat_channel.metadata["party_id"]).to eq(party.id)
    expect(party.party_memberships.find_by(user: leader).role).to eq("leader")
  end
end
