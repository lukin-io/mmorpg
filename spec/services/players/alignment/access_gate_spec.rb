require "rails_helper"

RSpec.describe Players::Alignment::AccessGate do
  let(:character) { create(:character, reputation: 100, faction_alignment: "alliance", alignment_score: 25) }

  it "returns structured reasons when requirements are not met" do
    result = described_class.new(character:).evaluate(
      reputation: 150,
      city: {reputation: 120, faction: "rebellion"}
    )

    expect(result.allowed?).to be_falsey
    expect(result.reasons).to include(:reputation, :city_faction, :city_reputation)
  end
end
