# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Professions::Craft do
  let(:character) { create(:character) }
  let(:rng) { instance_double(Random) }

  before do
    Game::Professions::Templates.instance_variable_set(:@craft_items_ensured, false)
    Game::Professions::Templates.ensure_craft_items!
    allow(rng).to receive(:rand).and_return(0.0)
    inventory = character.inventory
    manager = Game::Inventory::Manager.new(inventory:)
    manager.add_item!(item_template: ItemTemplate.find_by!(key: "pine_resin"), quantity: 2)
    manager.add_item!(item_template: ItemTemplate.find_by!(key: "wood_chips"), quantity: 4)
    manager.add_item!(item_template: ItemTemplate.find_by!(key: "rat_tail"), quantity: 2)
  end

  def craft(recipe_key, rng: self.rng)
    described_class.new(character:, recipe_key:, rng:).call
  end

  it "crafts an ashen bandage and raises tar_smith skill" do
    result = craft("ashen_bandage")

    expect(result.success).to be(true)
    expect(result.skill).to eq(1)
    expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "ashen_bandage"}).sum(:quantity)).to eq(1)
    expect(character.reload.metadata.dig("profession_skills", "tar_smith")).to eq(1)
  end

  it "crafts bandage from chips via fallback recipe" do
    result = craft("ashen_bandage_chips")
    expect(result.success).to be(true)
  end

  it "rejects craft without materials" do
    character.inventory.inventory_items.destroy_all

    result = craft("ashen_bandage")

    expect(result.success).to be(false)
    expect(character.inventory.inventory_items.joins(:item_template).where(item_templates: {key: "ashen_bandage"})).to be_empty
  end

  it "requires a clan laboratory before Blood III crafting" do
    result = craft("blood3_warlord_elixir")

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.professions.laboratory_required"))
  end

  it "keeps materials and skill when the success roll fails" do
    fail_rng = instance_double(Random)
    allow(fail_rng).to receive(:rand).and_return(0.99)

    resin_before = character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "pine_resin"}).sum(:quantity)

    result = craft("ashen_bandage", rng: fail_rng)

    expect(result.success).to be(false)
    expect(result.message).to eq(I18n.t("game.professions.craft_failed", name: "Пепельный бинт"))
    expect(character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "pine_resin"}).sum(:quantity)).to eq(resin_before)
    expect(character.reload.metadata.to_h.dig("profession_skills", "tar_smith").to_i).to eq(0)
    expect(character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "ashen_bandage"}).sum(:quantity)).to eq(0)
  end

  it "crafts rare ranger gear from rare hides and high-tier materials" do
    character.update!(metadata: {"profession_skills" => {"tar_smith" => 12}})
    manager = Game::Inventory::Manager.new(inventory: character.inventory)
    {
      "ash_wolf_pelt" => 3,
      "mist_spider_silk" => 2,
      "ember_cedar_plank" => 3
    }.each do |key, quantity|
      manager.add_item!(item_template: ItemTemplate.find_by!(key: key), quantity:)
    end

    result = craft("ash_ranger_jacket")

    expect(result.success).to be(true)
    crafted = character.inventory.inventory_items.joins(:item_template)
      .find_by!(item_templates: {key: "ash_ranger_jacket"})
    expect(crafted.item_template.requirements["level"]).to eq(12)
  end
end
