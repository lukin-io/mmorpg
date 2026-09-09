# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::FatigueService do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2026, 7, 27, 12, 0, 0) }
  let(:character) { create(:character, fatigue_percent: 86, fatigue_updated_at: now) }

  it "recovers one point per complete three-minute interval" do
    service = described_class.new(character:)

    expect(service.current_percent(at: now + 2.minutes + 59.seconds)).to eq(86)
    expect(service.current_percent(at: now + 3.minutes)).to eq(85)
    expect(service.current_percent(at: now + 300.minutes)).to eq(0)
  end

  it "locks wilderness Move, Look, and Enter at 86 percent" do
    service = described_class.new(character:)

    expect(service.outdoor_actions_blocked?(at: now)).to be(true)
    expect(service.outdoor_actions_blocked?(at: now + 3.minutes)).to be(false)
  end

  it "applies elapsed recovery before a bounded increase" do
    updated = described_class.new(character:).increase!(amount: 2, at: now + 3.minutes)

    expect(updated).to eq(87)
    expect(character.reload).to have_attributes(fatigue_percent: 87, fatigue_updated_at: now + 3.minutes)
  end

  it "rejects zero, negative, and null increases" do
    service = described_class.new(character:)

    [0, -1, nil].each do |amount|
      expect { service.increase!(amount:, at: now) }.to raise_error(ArgumentError, /positive/)
    end
  end

  it "uses injected recovery and gate parameters at their exact time boundary" do
    data = YAML.safe_load_file(Game::World::Rules::CONFIG_PATH, aliases: false)
    data.fetch("fatigue").merge!("recovery_interval_seconds" => 60, "recovery_points" => 2,
      "outdoor_action_lock_percent" => 85)
    service = described_class.new(character:, rules: Game::World::Rules.new(data:))

    expect(service.current_percent(at: now - 1.second)).to eq(86)
    expect(service.current_percent(at: now + 59.seconds)).to eq(86)
    expect(service.outdoor_actions_blocked?(at: now + 59.seconds)).to be true
    expect(service.current_percent(at: now + 60.seconds)).to eq(84)
    expect(service.outdoor_actions_blocked?(at: now + 60.seconds)).to be false
    expect(service.increase!(amount: 2, at: now + 60.seconds)).to eq(86)
    expect(character.reload.fatigue_updated_at).to eq(now + 60.seconds)
  end

  it "recovers the requested points after elapsed natural recovery and reports the actual decrease" do
    service = described_class.new(character:)

    expect(service.recover!(amount: 2, at: now + 3.minutes)).to eq(2)
    expect(character.reload).to have_attributes(fatigue_percent: 83, fatigue_updated_at: now + 3.minutes)
    expect(service.recover!(amount: 100, at: now + 3.minutes)).to eq(83)
    expect(character.reload.fatigue_percent).to eq(0)
    expect(service.recover!(amount: 2, at: now + 3.minutes)).to eq(0)
  end

  it "rejects malformed recovery amounts without changing persisted fatigue" do
    service = described_class.new(character:)

    [nil, 0, -1, "2", 1.5, true].each do |amount|
      expect { service.recover!(amount:, at: now) }.to raise_error(ArgumentError, /positive integer/)
    end
    expect(character.reload).to have_attributes(fatigue_percent: 86, fatigue_updated_at: now)
  end
end
