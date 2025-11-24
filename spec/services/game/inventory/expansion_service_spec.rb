require "rails_helper"

RSpec.describe Game::Inventory::ExpansionService do
  let(:character) { create(:character) }

  describe "housing expansions" do
    before { create(:housing_plot, user: character.user, storage_slots: 40) }

    it "boosts slot and weight capacity based on housing storage" do
      described_class.new(character:).expand!(source: :housing)

      inventory = character.reload.inventory
      expect(inventory.slot_capacity).to eq(40)
      expect(inventory.weight_capacity).to eq(200)
    end
  end

  describe "premium expansions" do
    before { character.user.update!(premium_tokens_balance: 50) }

    it "charges tokens and applies the default expansion bonuses" do
      described_class.new(character:).expand!(source: :premium, premium_cost: 25)

      inventory = character.reload.inventory
      expect(inventory.slot_capacity).to eq(35)
      expect(inventory.weight_capacity).to eq(150)
      expect(character.user.reload.premium_tokens_balance).to eq(25)
    end
  end
end
