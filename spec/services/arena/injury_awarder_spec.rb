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
end
