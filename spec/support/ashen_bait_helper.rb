# frozen_string_literal: true

module AshenBaitHelper
  def grant_bait!(character, quantity: 1)
    template = ItemTemplate.find_by(key: Game::World::Bait::ITEM_KEY) ||
      create(
        :item_template,
        :material,
        key: Game::World::Bait::ITEM_KEY,
        name: "Приманка Завесы",
        weight: 1,
        stack_limit: 99,
        base_price: 5
      )

    inventory = character.inventory || character.create_inventory!
    Game::Inventory::Manager.new(inventory:).add_item!(item_template: template, quantity:)
  end
end

RSpec.configure do |config|
  config.include AshenBaitHelper
end
