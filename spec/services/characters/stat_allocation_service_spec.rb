# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::StatAllocationService do
  let(:character) do
    create(:character, :neverlands_starter, stat_points_available: 3, current_hp: 2, current_mp: 3)
  end

  it "spends points atomically and derives HP/MP without healing" do
    result = described_class.new(character:).call(allocations: {health: 1, knowledge: 2})

    expect(result.remaining_points).to eq(0)
    expect(character.reload).to have_attributes(max_hp: 10, max_mp: 21, current_hp: 2, current_mp: 3)
    expect(character.allocated_stats).to eq("vitality" => 1, "intelligence" => 2)
  end

  it "rejects insufficient, empty, null, and unknown allocations" do
    service = described_class.new(character:)

    expect { service.call(allocations: {strength: 4}) }
      .to raise_error(described_class::AllocationError, /Not enough/)
    expect { service.call(allocations: {}) }
      .to raise_error(described_class::AllocationError, /No stats/)
    expect { service.call(allocations: {strength: nil}) }
      .to raise_error(described_class::AllocationError, /No stats/)
    expect { service.call(allocations: {invented: 1}) }
      .to raise_error(described_class::AllocationError, /No stats/)
  end

  it "reloads under the row lock for stale competing allocations" do
    first = Character.find(character.id)
    stale_second = Character.find(character.id)

    described_class.new(character: first).call(allocations: {strength: 2})

    expect {
      described_class.new(character: stale_second).call(allocations: {health: 2})
    }.to raise_error(described_class::AllocationError, /Not enough/)
    expect(character.reload.stat_points_available).to eq(1)
  end
end
