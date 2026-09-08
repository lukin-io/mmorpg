# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Skills::PerkAllocation do
  subject(:allocation) { described_class.new(character) }

  let(:character) { create(:character, :with_new_perk_point, perks: {}) }

  it "persists a captured binary perk and spends one point" do
    result = allocation.call(selected_keys: [:more_strength])

    expect(result.selected_keys).to eq(["more_strength"])
    expect(result.remaining_points).to eq(0)
    expect(character.reload).to be_owns_perk(:more_strength)
    expect(character.perk_points).to eq(0)
  end

  it "allows the source-backed Careful Fighter perk" do
    result = allocation.call(selected_keys: [:careful_fighter])

    expect(result.selected_keys).to eq(["careful_fighter"])
    expect(character.reload).to be_owns_perk(:careful_fighter)
    expect(character.perk_points).to eq(0)
  end

  it "does not infer a strength effect from the perk label" do
    strength_before = character.stats.get(:strength)

    allocation.call(selected_keys: [:more_strength])

    expect(character.reload.stats.get(:strength)).to eq(strength_before)
  end

  it "rejects an unknown perk without spending points" do
    expect do
      allocation.call(selected_keys: [:invented_perk])
    end.to raise_error(described_class::AllocationError, "Unknown perk selection")

    expect(character.reload.perk_points).to eq(1)
    expect(character.perks).to eq({})
  end

  it "rejects an empty selection" do
    expect do
      allocation.call(selected_keys: [])
    end.to raise_error(described_class::AllocationError, "No new perks selected")
  end

  it "rejects a null selection" do
    expect do
      allocation.call(selected_keys: nil)
    end.to raise_error(described_class::AllocationError, "No new perks selected")
  end

  it "normalizes blank and duplicate selections before spending" do
    result = allocation.call(selected_keys: ["", " more_strength ", :more_strength])

    expect(result.selected_keys).to eq(["more_strength"])
    expect(character.reload.perk_points).to eq(0)
  end

  it "rejects allocation without enough points" do
    character = create(:character, :without_perk_points)
    allocation = described_class.new(character)

    expect do
      allocation.call(selected_keys: [:more_strength])
    end.to raise_error(described_class::AllocationError, "Not enough new-perk points")
  end

  it "does not charge again for an owned perk" do
    character.update!(perks: {"more_strength" => true})

    expect do
      allocation.call(selected_keys: [:more_strength])
    end.to raise_error(described_class::AllocationError, "No new perks selected")

    expect(character.reload.perk_points).to eq(1)
  end

  it "rejects mutually exclusive selections before persistence" do
    allow(Game::Skills::PerkRegistry).to receive(:conflicts_for).and_return([[1, 2]])

    expect do
      allocation.call(selected_keys: [:more_strength])
    end.to raise_error(described_class::AllocationError, "Selected perks are mutually exclusive")

    expect(character.reload.perks).to eq({})
  end
end
