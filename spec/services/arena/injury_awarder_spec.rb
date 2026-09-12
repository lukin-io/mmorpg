# frozen_string_literal: true

require "rails_helper"
RSpec.describe Arena::InjuryAwarder do
  include ActiveSupport::Testing::TimeHelpers
  let(:match) { create(:arena_match, :live, trauma_percent: 30) }
  let(:player) { create(:character, allocated_stats: {"strength" => 99}) }
  before { create(:arena_participation, arena_match: match, character: player, user: player.user, team: "a", result: :defeat) }

  it "persists the observed named light injury once and expires its penalty" do
    service = described_class.new(match:, rng: instance_double(Random, rand: 0))
    injury = service.call.first
    expect(injury).to have_attributes(severity: "light", name: "Chest muscle hematoma")
    expect(service.call).to be_empty
    expect(player.reload.stats.get(:strength)).to eq(95)
    travel_to injury.expires_at, with_usec: true do
      expect(player.reload.stats.get(:strength)).to eq(100)
    end
  end

  it "can leave a loss uninjured and applies the guaranteed combat duration" do
    expect(described_class.new(match:, rng: instance_double(Random, rand: 99)).call).to be_empty
    match.update!(metadata: {"injury_risk" => "combat"})
    injury = described_class.new(match:).call.first
    expect(injury.expires_at).to be_within(1.second).of(24.hours.from_now)
    expect(injury.blocks_movement?).to be true
  end

  {"light" => [0, 30.minutes, 5], "medium" => [80, 2.hours, 15], "heavy" => [98, 6.hours, 30]}.each do |severity, (roll, duration, penalty)|
    it "can award #{severity} at low ordinary risk with its own duration and penalty" do
      match.update!(trauma_percent: 10)
      rng = instance_double(Random)
      allow(rng).to receive(:rand).with(100).and_return(0, roll)
      injury = described_class.new(match:, rng:).call.sole
      expect(injury).to have_attributes(severity:, stat_penalty_percent: penalty)
      expect(injury.expires_at).to be_within(1.second).of(duration.from_now)
      expect(described_class.new(match:, rng:).call).to be_empty
    end
  end

  it "does not make high ordinary trauma guarantee a heavy injury" do
    match.update!(trauma_percent: 80)
    injury = described_class.new(match:, rng: instance_double(Random, rand: 0)).call.sole
    expect(injury.severity).to eq("light")
  end

  {"light" => [0, 2250], "medium" => [80, 9000], "heavy" => [98, 27000]}.each do |severity, (roll, seconds)|
    it "preserves fractional-hour/minute extension when stacking #{severity}" do
      player.character_injuries.create!(severity: "light", name: "Existing injury", stat_penalty_percent: 5, expires_at: 10.minutes.from_now)
      rng = instance_double(Random)
      allow(rng).to receive(:rand).with(100).and_return(0, roll)
      freeze_time do
        injury = described_class.new(match:, rng:).call.sole
        expect(injury.expires_at).to eq(Time.current + seconds)
      end
    end
  end

  it "preserves a guaranteed decisive-timeout heavy injury without random rolls" do
    match.update!(timed_out: true, winning_team: "b", trauma_percent: 10)
    rng = instance_double(Random)
    expect(rng).not_to receive(:rand)
    expect(described_class.new(match:, rng:).call.sole.severity).to eq("heavy")
  end

  it "never rerolls an uninjured completed result on finalization replay" do
    create(:arena_participation, arena_match: match, team: "b")
    first = Arena::CombatProcessor.new(match, rng: instance_double(Random, rand: 99))
    expect(first.end_match("b")).to be true
    expect(player.character_injuries).to be_empty
    expect(Arena::CombatProcessor.new(match.reload, rng: instance_double(Random, rand: 0)).end_match("b")).to be false
    expect(player.character_injuries.reload).to be_empty
  end
end
