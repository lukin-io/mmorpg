# frozen_string_literal: true

require "rails_helper"

RSpec.describe Character, "combat benefits" do
  let(:now) { Time.utc(2026, 9, 11, 12) }
  let(:expiry) { "2026-09-11T15:01:00+03:00" }

  def expect_standard(character)
    policy = character.combat_benefits(now: now)
    expect(policy.drop_level_range(player_level: 17)).to eq(15..19)
    expect(policy.maximum_experience(base_cap: 100_000)).to eq(100_000)
  end

  it "resolves the persisted server entitlement without changing metadata" do
    character = create(:character, metadata: {
      "combat_entitlement" => {"tier" => "gold", "expires_at" => expiry},
      "unrelated" => "preserved"
    }).reload
    original = character.metadata.deep_dup

    policy = character.combat_benefits(now: now)

    expect(policy).to be_a(Game::Combat::PremiumBenefits)
    expect(policy.drop_level_range(player_level: 17)).to eq(13..21)
    expect(policy.maximum_experience(base_cap: 100_000)).to eq(200_000)
    expect(character).not_to be_changed
    expect(character.reload.metadata).to eq(original)
  end

  [nil, [], "vip", 1, true, {}, {"combat_entitlement" => nil},
    {"combat_entitlement" => []}, {"combat_entitlement" => "vip"},
    {"tier" => "vip", "expires_at" => "2027-01-01T00:00:00Z"}].each do |metadata|
    it "falls back for malformed or missing entitlement metadata #{metadata.inspect}" do
      expect_standard(build(:character, metadata: metadata))
    end
  end

  [nil, "", "not-a-date", 1, {}, true, "2026-09-11", "2026-09-11T12:01:00",
    "2026-09-31T12:01:00Z", "2026-13-01T12:01:00Z", "2026-09-11T25:01:00Z"].each do |timestamp|
    it "falls back for invalid or timezone-less expiry #{timestamp.inspect}" do
      expect_standard(build(:character, metadata: {
        "combat_entitlement" => {"tier" => "vip", "expires_at" => timestamp}
      }))
    end
  end

  [nil, "unknown", "VIP", [], {}, true].each do |tier|
    it "falls back for invalid tier #{tier.inspect} even with valid future expiry" do
      expect_standard(build(:character, metadata: {
        "combat_entitlement" => {"tier" => tier, "expires_at" => expiry}
      }))
    end
  end

  it "uses the server clock by default and expires at the exact fractional instant" do
    deadline = now + Rational(1, 2)
    character = build(:character, metadata: {
      "combat_entitlement" => {"tier" => "vip", "expires_at" => deadline.iso8601(6)}
    })
    allow(Time).to receive(:current).and_return(deadline - Rational(1, 1_000_000))
    expect(character.combat_benefits.maximum_experience(base_cap: 100)).to eq(250)
    allow(Time).to receive(:current).and_return(deadline)
    expect(character.combat_benefits.maximum_experience(base_cap: 100)).to eq(100)
    allow(Time).to receive(:current).and_return(deadline + Rational(1, 1_000_000))
    expect(character.combat_benefits.maximum_experience(base_cap: 100)).to eq(100)
  end
end
