# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Game::Inventory::Manager bandage injury clear" do
  it "heals and clears light injuries when using ashen_bandage" do
    Game::Professions::Templates.ensure_craft_items!
    character = create(:character, current_hp: 20, max_hp: 100)
    Game::Combat::InjuryState.new(character:).apply!(severity: "light", duration: 1.hour)
    Game::Combat::InjuryState.new(character:).apply!(severity: "heavy", duration: 1.hour)

    template = ItemTemplate.find_by!(key: "ashen_bandage")
    inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
    item = Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity: 1)

    result = Game::Inventory::Manager.use_item(character, item.reload)

    expect(result[:success]).to be(true)
    expect(result[:message]).to match(/HP|40|травм|injur/i)
    expect(Game::Combat::InjuryState.new(character: character.reload).blocks_movement?).to be(true)
    expect(Game::Combat::InjuryState.new(character:).active.map { |row| row["severity"] }).to eq(["heavy"])
  end
end
