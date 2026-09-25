# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::InquisitionImmunity do
  it "blocks assaults against INQ members" do
    attacker = create(:character)
    defender = create(:character, metadata: {"inquisition_member" => true})

    expect(described_class.inquisitor?(defender)).to eq(true)
    expect(described_class.blocked?(attacker:, defender:)).to eq(true)
    expect(Game::World::StartPlayerAssault.offerable?(attacker:, defender:)).to eq(false)
  end
end

RSpec.describe Game::Combat::InjuryResolver do
  it "applies heavy trauma from a bloody assault scroll, not crit intensity" do
    match = create(
      :arena_match,
      trauma_percent: 100,
      metadata: {"assault_scroll_kind" => "bloody", "combat_trauma" => true}
    )
    loser = create(:character)
    create(
      :arena_participation,
      arena_match: match,
      character: loser,
      user: loser.user,
      team: "a",
      result: "defeat",
      metadata: {
        "critical_hits_taken" => 0,
        "critical_damage_taken" => 0,
        "head_hits_taken" => 0
      }
    )
    winner = create(:character)
    create(
      :arena_participation,
      arena_match: match,
      character: winner,
      user: winner.user,
      team: "b",
      result: "victory"
    )

    results = described_class.new(match:, rng: Random.new(1)).call
    expect(results.map(&:severity)).to include("heavy")
    expect(loser.reload.metadata["ashen_injuries"]).to be_present
  end
end

RSpec.describe Game::Shop::PremiumGateway do
  it "denies stub IAP by default" do
    previous = ENV["ALLOW_STUB_IAP"]
    ENV["ALLOW_STUB_IAP"] = "false"
    expect(described_class.stub_iap_allowed?).to eq(false)
    expect {
      described_class.assert_stub_allowed!
    }.to raise_error(described_class::StubDisabled)
  ensure
    ENV["ALLOW_STUB_IAP"] = previous
  end
end
