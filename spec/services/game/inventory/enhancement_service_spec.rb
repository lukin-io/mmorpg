require "rails_helper"

RSpec.describe Game::Inventory::EnhancementService do
  let(:item_template) do
    create(:item_template, enhancement_rules: {"base_success_chance" => 100, "required_skill_level" => 5})
  end
  let(:inventory_owner) { create(:character) }
  let(:inventory_item) { create(:inventory_item, inventory: inventory_owner.inventory, item_template:) }
  let(:profession) { create(:profession, name: "Blacksmithing") }
  let(:skilled_progress) { create(:profession_progress, profession:, skill_level: 6) }
  let(:unskilled_progress) { create(:profession_progress, profession:, skill_level: 1) }

  it "raises when crafter skill is too low" do
    expect {
      described_class.new(item: inventory_item, crafter_progress: unskilled_progress).attempt!
    }.to raise_error(Pundit::NotAuthorizedError)
  end

  it "increments enhancement level on success" do
    result = described_class.new(item: inventory_item, crafter_progress: skilled_progress, rng: Random.new(1)).attempt!

    expect(result).to eq(:success)
    expect(inventory_item.reload.enhancement_level).to eq(1)
  end
end
