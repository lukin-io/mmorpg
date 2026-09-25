# frozen_string_literal: true

# Ensures ashen_bait exists in the live catalog and outdoor passive windows are
# the Ashen five-minute rule after deploy.
class SeedAshenBaitAndFiveMinutePassive < ActiveRecord::Migration[8.1]
  FIVE_MINUTE_WINDOW = [{"key" => "ashen_five_minutes", "min_seconds" => 300, "max_seconds" => 300}].freeze

  def up
    if defined?(ItemTemplate)
      bait = ItemTemplate.find_or_initialize_by(key: "ashen_bait")
      bait.assign_attributes(
        name: "Приманка Завесы",
        item_type: "material",
        slot: "material",
        weight: 1,
        stack_limit: 99,
        base_price: 5,
        durability_max: 1,
        requirements: {},
        stat_modifiers: {},
        enhancement_rules: bait.enhancement_rules.to_h.merge(
          "inventory_family" => "things",
          "subcategory" => "misc",
          "source_name" => "Приманка Завесы",
          "description" => "Вызывает бой с ботом на текущей клетке. Без приманки боты сами нападают примерно раз в 5 минут.",
          "icon" => "/ashen/items/consumables/ashen-bait.png",
          "shop" => {"sold" => true, "mode" => "buy", "position" => 90},
          "shop_stock" => bait.enhancement_rules.to_h.dig("shop_stock").presence || {"current" => 500, "max" => 500}
        )
      )
      bait.save!
      say "seeded ashen_bait"

      if defined?(Character) && defined?(Game::Inventory::Manager)
        granted = 0
        Character.find_each do |character|
          inventory = character.inventory || character.create_inventory!
          existing = inventory.inventory_items.where(item_template: bait, equipped: false).sum(:quantity)
          next if existing >= Game::World::Bait::STARTER_GRANT

          Game::Inventory::Manager.new(inventory:).add_item!(
            item_template: bait,
            quantity: Game::World::Bait::STARTER_GRANT - existing
          )
          granted += 1
        end
        say "granted starter ashen_bait to #{granted} characters"
      end
    end

    if defined?(TileNpc)
      updated = 0
      TileNpc.find_each do |npc|
        meta = npc.metadata.to_h
        next if meta["passive_delay_windows"] == FIVE_MINUTE_WINDOW

        npc.update!(metadata: meta.merge("passive_delay_windows" => FIVE_MINUTE_WINDOW))
        updated += 1
      end
      say "updated passive windows on #{updated} tile NPCs"
    end

    outdoor_path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load outdoor_path if File.exist?(outdoor_path)
  end

  def down
  end
end
