# frozen_string_literal: true

# Deliberately avoids rails_helper and its shared-database cleanup hooks.
require "spec_helper"
require "active_support"
require "active_support/time"
require_relative "../../../../app/lib/game/combat/premium_benefits"

RSpec.describe Game::Combat::PremiumBenefits do
  let(:now) { Time.utc(2026, 9, 11, 12) }
  let(:expires_at) { now + 60 }

  def benefits(tier: nil, expires_at: self.expires_at, now: self.now)
    described_class.new(tier: tier, expires_at: expires_at, now: now)
  end

  def expect_standard(policy)
    expect(policy.drop_level_range(player_level: 17)).to eq(15..19)
    expect(policy.maximum_experience(base_cap: 100_000)).to eq(100_000)
  end

  {
    "standard" => [2, 100_000],
    "premium" => [2, 150_000],
    "gold" => [4, 200_000],
    "vip" => [6, 250_000],
    "worker" => [2, 100_000]
  }.each do |tier, (window, cap)|
    it "uses #{tier}'s total drop window and maximum fight XP" do
      [tier, tier.to_sym].each do |tier_input|
        policy = benefits(tier: tier_input)
        range = policy.drop_level_range(player_level: 17)

        expect(range).to eq((17 - window)..(17 + window))
        expect(range.cover?(17 - window)).to be(true)
        expect(range.cover?(17 + window)).to be(true)
        expect(range.cover?(16 - window)).to be(false)
        expect(range.cover?(18 + window)).to be(false)
        expect(policy.maximum_experience(base_cap: 100_000)).to eq(cap)
      end
    end
  end

  it "uses standard benefits without an entitlement" do
    expect_standard(described_class.new(now: now))
  end

  [nil, "", "unknown", :unknown, "Gold", " vip ", 1, true, [], {tier: "vip"}].each do |tier|
    it "falls back safely for malformed or unknown tier #{tier.inspect}" do
      expect_standard(benefits(tier: tier))
    end
  end

  it "does not trust arbitrary objects that stringify as a paid tier" do
    tier = double("tier", to_s: "vip")
    expect_standard(benefits(tier: tier))
  end

  %w[premium gold vip].each do |tier|
    it "expires #{tier} exactly at the server deadline" do
      expect(benefits(tier: tier, now: expires_at - Rational(1, 1_000_000))
        .maximum_experience(base_cap: 100)).to be > 100
      expect_standard(benefits(tier: tier, now: expires_at))
      expect_standard(benefits(tier: tier, now: expires_at + Rational(1, 1_000_000)))
    end
  end

  [nil, "2027-01-01T00:00:00Z", 9_999_999_999, Float::INFINITY, true, {}, [], Date.new(2027, 1, 1)].each do |expiry|
    it "falls back safely for missing or malformed expiry #{expiry.inspect}" do
      expect_standard(benefits(tier: :vip, expires_at: expiry))
    end
  end

  it "compares instants across UTC offsets and accepts Rails server times" do
    zoned_now = now.in_time_zone("Kyiv")
    zoned_expiry = expires_at.in_time_zone("America/New_York")
    expect(benefits(tier: :gold, now: zoned_now, expires_at: zoned_expiry)
      .maximum_experience(base_cap: 100)).to eq(200)
    expect_standard(benefits(tier: :gold, now: zoned_expiry, expires_at: expires_at))
  end

  it "keeps one deterministic snapshot until a new decision is constructed" do
    policy = benefits(tier: :gold)
    allow(Time).to receive(:now).and_return(expires_at + 3600)

    2.times { expect(policy.maximum_experience(base_cap: 100)).to eq(200) }
    expect_standard(benefits(tier: :gold, now: expires_at))
  end

  it "preserves the non-negative level boundary and zero XP cap" do
    expect(benefits.drop_level_range(player_level: 0)).to eq(0..2)
    expect(benefits(tier: :vip).drop_level_range(player_level: 0)).to eq(0..6)
    expect(benefits(tier: :gold).drop_level_range(player_level: 3)).to eq(0..7)
    expect(benefits(tier: :vip).maximum_experience(base_cap: 0)).to eq(0)
  end

  it "returns an exact integer maximum without rounding above a fractional cap" do
    expect(benefits(tier: :premium).maximum_experience(base_cap: 3)).to eq(4)
    expect(benefits(tier: :vip).maximum_experience(base_cap: 3)).to eq(7)
    base_cap = 10**30 + 1
    expect(benefits(tier: :vip).maximum_experience(base_cap: base_cap)).to eq(base_cap * 5 / 2)
  end

  [nil, "10", -1, 1.5, Float::INFINITY, true].each do |value|
    it "rejects invalid authoritative level/cap input #{value.inspect}" do
      expect { benefits.drop_level_range(player_level: value) }.to raise_error(ArgumentError, /player_level/)
      expect { benefits.maximum_experience(base_cap: value) }.to raise_error(ArgumentError, /base_cap/)
    end
  end

  it "requires an explicit valid server time" do
    expect { described_class.new }.to raise_error(ArgumentError, /now/)
    [nil, "2026-09-11T12:00:00Z", 0, Date.today].each do |invalid_now|
      expect { benefits(now: invalid_now) }.to raise_error(ArgumentError, /now/)
    end
  end

  it "pins every configured tier including the no-benefit tiers to the captured contract" do
    expect(described_class::CONFIG).to eq(
      "standard" => {"drop_level_window" => 2, "experience_cap_multiplier" => 1.0},
      "premium" => {"drop_level_window" => 2, "experience_cap_multiplier" => 1.5},
      "gold" => {"drop_level_window" => 4, "experience_cap_multiplier" => 2.0},
      "vip" => {"drop_level_window" => 6, "experience_cap_multiplier" => 2.5},
      "worker" => {"drop_level_window" => 2, "experience_cap_multiplier" => 1.0}
    )
  end

  [nil, [], "vip", {}, {"drop_level_window" => 6},
    {"drop_level_window" => "6", "experience_cap_multiplier" => 2.5},
    {"drop_level_window" => 6, "experience_cap_multiplier" => "2.5"},
    {"drop_level_window" => 8, "experience_cap_multiplier" => 2.5},
    {"drop_level_window" => 6, "experience_cap_multiplier" => 3.0},
    {"drop_level_window" => 6, "experience_cap_multiplier" => Float::NAN}].each do |row|
    it "uses standard limits when the configured paid-tier row is malformed: #{row.inspect}" do
      stub_const("#{described_class}::CONFIG", {"vip" => row})
      expect_standard(benefits(tier: :vip))
    end
  end

  it "cannot enable unknown or worker combat benefits through config alone" do
    row = {"drop_level_window" => 6, "experience_cap_multiplier" => 2.5}
    stub_const("#{described_class}::CONFIG", {"unknown" => row, "worker" => row})
    expect_standard(benefits(tier: "unknown"))
    expect_standard(benefits(tier: :worker))
  end
end
