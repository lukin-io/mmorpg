# frozen_string_literal: true

class ExtendHousingPlotsAndDecor < ActiveRecord::Migration[8.1]
  def change
    change_table :housing_plots, bulk: true do |t|
      t.string :plot_tier, null: false, default: "starter"
      t.string :exterior_style, null: false, default: "classic"
      t.integer :room_slots, null: false, default: 1
      t.integer :utility_slots, null: false, default: 1
      t.string :visit_scope, null: false, default: "friends"
      t.references :visit_guild, foreign_key: {to_table: :guilds}, index: false
      t.boolean :showcase_enabled, null: false, default: false
    end
    add_index :housing_plots, :plot_tier
    add_index :housing_plots, :visit_scope
    add_index :housing_plots, :visit_guild_id

    change_table :housing_decor_items, bulk: true do |t|
      t.string :decor_type, null: false, default: "furniture"
      t.jsonb :metadata, null: false, default: {}
      t.integer :utility_slot
    end
    add_index :housing_decor_items, :decor_type
  end
end
