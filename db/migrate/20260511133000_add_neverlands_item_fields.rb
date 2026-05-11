# frozen_string_literal: true

class AddNeverlandsItemFields < ActiveRecord::Migration[8.1]
  def change
    add_column :item_templates, :requirements, :jsonb, default: {}, null: false
    add_column :item_templates, :base_price, :integer, default: 0, null: false
    add_column :item_templates, :durability_max, :integer, default: 0, null: false
  end
end
