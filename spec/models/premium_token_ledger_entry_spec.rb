require "rails_helper"

RSpec.describe PremiumTokenLedgerEntry, type: :model do
  it "validates numeric delta" do
    entry = build(:premium_token_ledger_entry, delta: 0)

    expect(entry).not_to be_valid
    expect(entry.errors[:delta]).to be_present
  end
end
