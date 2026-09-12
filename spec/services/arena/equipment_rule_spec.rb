# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::EquipmentRule do
  let(:character) { create(:character) }

  it "checks clothing as well as weapons for unarmed admission" do
    expect(described_class.new("no_weapons").rejection_reason(character)).to be_nil
    create(:inventory_item, inventory: character.inventory, equipped: true, equipment_slot: "head")
    expect(described_class.new("no_weapons").rejection_reason(character)).to include("Remove all equipment")
    expect(described_class.new("free").rejection_reason(character)).to be_nil
  end

  it "applies authored artifact grades and rejects an unknown grade in restricted fights" do
    character.update!(metadata: {artifact_grade: "small"})
    expect(described_class.new("no_artifacts").rejection_reason(character)).to be_present
    expect(described_class.new("limited_artifacts").rejection_reason(character)).to be_nil
    character.update!(metadata: {artifact_grade: "large"})
    expect(described_class.new("limited_artifacts").rejection_reason(character)).to be_present
    character.update!(metadata: {artifact_grade: "unexpected"})
    expect(described_class.new("limited_artifacts").rejection_reason(character)).to be_present
  end
end
