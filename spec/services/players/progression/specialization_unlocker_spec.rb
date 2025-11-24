require "rails_helper"

RSpec.describe Players::Progression::SpecializationUnlocker do
  let(:character) { create(:character) }
  let(:quest_chain) { create(:quest_chain) }
  let(:quest) { create(:quest, quest_chain:, key: "holy_trial") }
  let(:specialization) do
    create(:class_specialization, character_class: character.character_class, unlock_requirements: {"quest" => quest.key})
  end

  before do
    create(:quest_assignment, quest:, character:, status: :completed)
  end

  it "assigns the specialization when the quest is completed" do
    described_class.new(character:, specialization:).unlock!

    expect(character.reload.secondary_specialization).to eq(specialization)
  end
end
