# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::TimedBuffs do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character, max_hp: 100) }

  around { |example| freeze_time { example.run } }

  it "applies modifiers and replaces the same buff key" do
    buffs = described_class.new(character:)
    buffs.apply!(key: "strength_brew", label: "Strength Brew", mods: {attack: 8}, duration_seconds: 3600)
    buffs.apply!(key: "strength_brew", label: "Strength Brew", mods: {attack: 12}, duration_seconds: 3600)

    expect(buffs.modifier(:attack)).to eq(12)
    expect(character.reload.metadata["active_buffs"].size).to eq(1)
  end

  it "prunes expired buffs on read and removes their character modifiers" do
    described_class.new(character:).apply!(
      key: "vigor",
      label: "Vigor",
      mods: {max_hp: 80},
      duration_seconds: 3600
    )
    expect(character.effective_max_hp).to eq(180)

    travel 1.hour + 1.second

    expect(character.reload.effective_max_hp).to eq(100)
    expect(character.reload.metadata["active_buffs"]).to eq([])
  end

  it "keeps only one Blood III potion active" do
    buffs = described_class.new(character:)
    buffs.apply!(key: "blood3_a", label: "A", mods: {attack: 10}, blood_tier: 3)
    buffs.apply!(key: "blood3_b", label: "B", mods: {defense: 10}, blood_tier: 3)

    expect(buffs.active.pluck("key")).to eq(["blood3_b"])
  end

  it "adds the Blood I triad until the earliest potion expires" do
    buffs = described_class.new(character:)
    buffs.apply!(key: "blood1_a", label: "A", mods: {attack: 1}, duration_seconds: 1800, blood_tier: 1)
    buffs.apply!(key: "blood1_b", label: "B", mods: {defense: 1}, duration_seconds: 2400, blood_tier: 1)
    buffs.apply!(key: "blood1_c", label: "C", mods: {luck: 1}, duration_seconds: 3600, blood_tier: 1)

    expect(buffs.modifier(:attack)).to eq(6)
    set = buffs.active.find { |entry| entry["key"] == described_class::BLOOD_I_SET_KEY }
    expect(Time.zone.parse(set["expires_at"])).to eq(30.minutes.from_now)
  end
end
