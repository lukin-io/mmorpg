# frozen_string_literal: true

require "rails_helper"

RSpec.describe Characters::SkillAllocationService do
  let(:character) { create(:character, combat_skill_points: 2, peace_skill_points: 2) }

  it "spends combat and peace pools independently" do
    combat_key = Game::Skills::PassiveSkillRegistry.by_pool(:combat).first.fetch(:key)
    peace_key = Game::Skills::PassiveSkillRegistry.by_pool(:peace).first.fetch(:key)

    result = described_class.new(character:).call(allocations: {combat_key => 1, peace_key => 1})

    expect(result.combat_points_remaining).to eq(1)
    expect(result.peace_points_remaining).to eq(1)
    expect(character.reload.base_passive_skill_level(combat_key)).to be_positive
    expect(character.base_passive_skill_level(peace_key)).to be_positive
  end

  it "does not consume a point for an unknown or already-maxed skill" do
    combat = Game::Skills::PassiveSkillRegistry.by_pool(:combat).first
    character.update!(passive_skills: {combat.fetch(:key).to_s => combat.fetch(:max_level, 100)})

    expect {
      described_class.new(character:).call(allocations: {invented: 1, combat.fetch(:key) => 1})
    }.to raise_error(described_class::AllocationError, /No allocatable/)
    expect(character.reload.combat_skill_points).to eq(2)
  end

  it "rejects pool over-allocation and empty/null input" do
    combat_key = Game::Skills::PassiveSkillRegistry.by_pool(:combat).first.fetch(:key)
    service = described_class.new(character:)

    expect { service.call(allocations: {combat_key => 3}) }
      .to raise_error(described_class::AllocationError, /combat/)
    expect { service.call(allocations: {}) }
      .to raise_error(described_class::AllocationError, /No skills/)
    expect { service.call(allocations: {combat_key => nil}) }
      .to raise_error(described_class::AllocationError, /No skills/)
  end

  it "reloads under the row lock for stale competing allocations" do
    combat_key = Game::Skills::PassiveSkillRegistry.by_pool(:combat).first.fetch(:key)
    character.update!(combat_skill_points: 1)
    first = Character.find(character.id)
    stale_second = Character.find(character.id)

    described_class.new(character: first).call(allocations: {combat_key => 1})

    expect {
      described_class.new(character: stale_second).call(allocations: {combat_key => 1})
    }.to raise_error(described_class::AllocationError, /combat/)
    expect(character.reload.combat_skill_points).to eq(0)
  end
end
