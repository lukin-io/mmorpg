require "rails_helper"

RSpec.describe Game::Combat::EncounterBuilder do
  let(:initiator) { create(:character, :with_position) }
  let(:target) { create(:character, :with_position) }

  it "creates a battle with participants and initiative order" do
    battle = described_class.new(initiator:, targets: target, mode: :pvp).call

    expect(battle).to be_persisted
    expect(battle.battle_participants.count).to eq(2)
    expect(battle.initiative_order).not_to be_empty
  end
end
