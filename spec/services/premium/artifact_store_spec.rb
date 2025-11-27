require "rails_helper"

RSpec.describe Premium::ArtifactStore do
  let(:user) { create(:user, premium_tokens_balance: 1000) }
  let(:character) { create(:character, user:) }

  it "purchases an item and debits premium tokens" do
    store = described_class.new(user: user, character: character)
    artifact = Premium::ArtifactStore::ARTIFACTS.find { |a| a[:key] == "xp_boost_7d" }

    expect do
      result = store.purchase!(artifact_key: "xp_boost_7d")
      expect(result[:success]).to be true
    end.to change { user.reload.premium_tokens_balance }.by(-artifact[:price])
  end

  it "returns error when user has insufficient tokens" do
    user.update!(premium_tokens_balance: 10)
    store = described_class.new(user: user, character: character)

    result = store.purchase!(artifact_key: "phoenix_mount")

    expect(result[:success]).to be false
    expect(result[:error]).to eq("Insufficient tokens")
  end

  it "returns error when trying to buy unique item already owned" do
    store = described_class.new(user: user, character: character)
    store.purchase!(artifact_key: "wings_of_glory")

    result = store.purchase!(artifact_key: "wings_of_glory")

    expect(result[:success]).to be false
    expect(result[:error]).to eq("Already owned")
  end
end
