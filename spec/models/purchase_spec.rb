require "rails_helper"

RSpec.describe Purchase, type: :model do
  it "is valid with defaults" do
    expect(build(:purchase)).to be_valid
  end

  it "enforces positive amount" do
    purchase = build(:purchase, amount_cents: 0)

    expect(purchase).not_to be_valid
  end
end
