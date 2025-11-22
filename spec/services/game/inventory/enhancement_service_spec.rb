require "rails_helper"

RSpec.describe Game::Inventory::EnhancementService do
  let(:item_template) { create(:item_template, enhancement_rules: {"base_success_chance" => 100, "required_skill_level" => 1}) }
  let(:inventory_item) { create(:inventory_item, item_template:) }
  let(:progress) { create(:profession_progress, profession: create(:profession, name: "Blacksmithing")) }

  it "raises when crafter skill is too low" do
    progress.update!(skill_level: 0)

    expect {
      described_class.new(item: inventory_item, crafter_progress: progress).attempt!
    }.to raise_error(Pundit::NotAuthorizedError)
  end

  it "increments enhancement level on success" do
    result = described_class.new(item: inventory_item, crafter_progress: progress, rng: Random.new(1)).attempt!

    expect(result).to eq(:success)
    expect(inventory_item.reload.enhancement_level).to eq(1)
  end
end

