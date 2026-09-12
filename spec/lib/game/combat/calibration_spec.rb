# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::Calibration do
  let(:player) { {strength: 112, weapon_damage: 25, mastery: 150, damage_multiplier: 1.1, penetration: 75, armor: 528} }
  let(:ogre) { {strength: 120, weapon_damage: 40, damage_multiplier: 2.55, armor: 470, armor_multiplier: 3.0, penetration: 75} }

  def hit(attacker, defender, critical: false, body: 1.0, action: 1.0)
    described_class.damage(attacker:, defender:, critical:, action_multiplier: action, body_multiplier: body, variance: 1.0)
  end

  it "matches the observed low, regular and Ogre difficulty bands with one equation" do
    expect(hit(player, {armor: 7}, critical: true, body: 1.3, action: 1.2)).to be_between(1500, 1800)
    expect(hit(player, {armor: 340}, critical: true, body: 1.3, action: 1.2)).to be_between(800, 1150)
    expect(hit(player, ogre, body: 1.3, action: 1.2)).to eq(0)
    expect(hit(ogre, player, critical: true, body: 1.1)).to be_between(450, 600)
    expect(hit(ogre.merge(strength: 137, weapon_damage: 45, penetration: 80), player, critical: true, body: 1.3)).to be_between(740, 900)
  end

  it "keeps armor, penetration, mastery and resistance independently effective" do
    baseline = hit(player, {armor: 340})
    expect(hit(player.merge(penetration: 100), {armor: 340})).to be > baseline
    expect(hit(player.merge(mastery: 50), {armor: 340})).to be < baseline
    expect(hit(player, {armor: 340, resistance: 100})).to be_within(1).of(baseline / 2.0)
    expect(hit(player, {armor: 400})).to be < baseline
  end

  it "applies exact doubled critical damage and bounded fatigue penalties" do
    normal = hit(player, {armor: 100})
    expect(hit(player, {armor: 100}, critical: true)).to be_within(1).of(normal * 2)
    expect(described_class.fatigue_factor(50)).to eq(1)
    expect(described_class.fatigue_factor(100)).to eq(0.5)
    expect(hit(player.merge(fatigue: 100), {armor: 100})).to be < normal
  end

  it "keeps large positive and negative opposed ratings finite" do
    expect(described_class.opposed(900, 900)).to eq(0)
    expect(described_class.opposed(1_000_000, -70)).to be_between(0, 35)
    expect(described_class.opposed(100, 900)).to be < 0
  end

  it "rejects zero recovery and loot divisors when loading authored content" do
    Tempfile.create(["combat-calibration", ".yml"]) do |file|
      values = YAML.safe_load_file(Rails.root.join("config/gameplay/combat_calibration.yml"))
      values["recovery"]["hp_full_seconds"] = 0
      file.write(values.to_yaml)
      file.flush
      expect { described_class.load(file.path) }.to raise_error(ArgumentError, /hp_full_seconds must be positive/)
    end
  end
end
