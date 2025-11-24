require "rails_helper"

RSpec.describe Premium::ArtifactStore do
  let(:user) { create(:user, premium_tokens_balance: 200) }
  let(:character) { create(:character, user:) }

  before do
    user.currency_wallet.update!(premium_tokens_balance: 200)
  end

  it "redeems an XP boost and debits premium tokens" do
    store = described_class.new

    expect do
      store.purchase!(user:, artifact_key: :xp_boost, character:, metadata: {xp_amount: 500})
    end.to change { user.reload.premium_tokens_balance }.by(-Premium::ArtifactStore::ARTIFACTS[:xp_boost].cost)

    expect(character.reload.experience).to be > 0
  end
end
