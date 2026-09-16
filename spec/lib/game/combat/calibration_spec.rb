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

  it "uses bounded Health steps for hidden armor without creating armor on an unarmored fighter" do
    {0 => 100, 29 => 100, 30 => 105, 59 => 105, 60 => 110, 149 => 120, 150 => 125, 300 => 125}.each do |health, armor|
      expect(described_class.armor(armor: 100, health:)).to be_within(0.001).of(armor)
    end
    expect(described_class.armor(armor: 0, health: 150)).to eq(0)
    expect(hit(player, {armor: 340, health: 150})).to be < hit(player, {armor: 340, health: 29})
  end

  it "keeps both primary accuracy inputs useful without changing balanced builds' rating" do
    expect(described_class.accuracy(dexterity: 40, luck: 40, accuracy: 15)).to eq(215)
    expect(described_class.accuracy(dexterity: 40, luck: 80, accuracy: 15)).to be > 215
    expect(described_class.accuracy(dexterity: 80, luck: 40, accuracy: 15)).to be > 215
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

  it "rejects a zero Health armor step before combat can divide by it" do
    Tempfile.create(["combat-health-calibration", ".yml"]) do |file|
      values = YAML.safe_load_file(Rails.root.join("config/gameplay/combat_calibration.yml"))
      values["health_armor_step"] = 0
      file.write(values.to_yaml)
      file.flush
      expect { described_class.load(file.path) }.to raise_error(ArgumentError, /health_armor_step must be positive/)
    end
  end

  describe ".injury_severity" do
    {10 => {nil => 9000, "light" => 800, "medium" => 180, "heavy" => 20},
     30 => {nil => 7000, "light" => 2400, "medium" => 540, "heavy" => 60},
     50 => {nil => 5000, "light" => 4000, "medium" => 900, "heavy" => 100},
     80 => {nil => 2000, "light" => 6400, "medium" => 1440, "heavy" => 160}}.each do |risk, expected|
      it "gives the exact independent outcome distribution at #{risk}% risk" do
        outcomes = (0...100).flat_map do |chance_roll|
          (0...100).map { |severity_roll| described_class.injury_severity(risk:, chance_roll:, severity_roll:) }
        end
        expect(outcomes.tally).to eq(expected)
      end
    end

    it "keeps zero risk injury-free and includes the exact probability boundaries" do
      [nil, -1, 0].each do |risk|
        expect(described_class.injury_severity(risk:, chance_roll: 0, severity_roll: 99)).to be_nil
      end
      expect(described_class.injury_severity(risk: 10, chance_roll: 9, severity_roll: 79)).to eq("light")
      expect(described_class.injury_severity(risk: 10, chance_roll: 10, severity_roll: 0)).to be_nil
      expect(described_class.injury_severity(risk: 10, chance_roll: 0, severity_roll: 80)).to eq("medium")
      expect(described_class.injury_severity(risk: 10, chance_roll: 0, severity_roll: 97)).to eq("medium")
      expect(described_class.injury_severity(risk: 10, chance_roll: 0, severity_roll: 98)).to eq("heavy")
      expect(described_class.injury_severity(risk: 200, chance_roll: 99, severity_roll: 99)).to eq("heavy")
    end
  end

  it "rejects missing, fractional, negative, extra and incorrectly totaled injury weights" do
    invalid_weights = [nil, 100, {"light" => 100}, {"light" => 80, "medium" => 18, "heavy" => 1},
      {"light" => 80.0, "medium" => 18, "heavy" => 2}, {"light" => 80, "medium" => 21, "heavy" => -1},
      {"light" => 80, "medium" => 18, "heavy" => 2, "combat" => 0}]
    invalid_weights.each do |weights|
      Tempfile.create(["combat-injury-calibration", ".yml"]) do |file|
        values = YAML.safe_load_file(Rails.root.join("config/gameplay/combat_calibration.yml"))
        values["injuries"] = {"severity_weights" => weights}
        file.write(values.to_yaml)
        file.flush
        expect { described_class.load(file.path) }.to raise_error(ArgumentError)
      end
    end
  end
end
