# frozen_string_literal: true

class ExtendAchievementsAndTitles < ActiveRecord::Migration[8.1]
  def change
    change_table :achievements, bulk: true do |t|
      t.string :category, null: false, default: "general"
      t.boolean :account_wide, null: false, default: true
      t.references :title_reward, foreign_key: {to_table: :titles}
      t.integer :display_priority, null: false, default: 0
      t.jsonb :share_payload, null: false, default: {}
    end
    add_index :achievements, :category
    add_index :achievements, :display_priority

    change_table :titles, bulk: true do |t|
      t.jsonb :perks, null: false, default: {}
      t.boolean :priority_party_finder, null: false, default: false
    end

    create_table :title_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :title, null: false, foreign_key: true
      t.boolean :equipped, null: false, default: false
      t.string :source, null: false
      t.datetime :granted_at, null: false
      t.timestamps
    end
    add_index :title_grants, [:user_id, :title_id], unique: true

    change_table :users, bulk: true do |t|
      t.references :active_title, foreign_key: {to_table: :titles}
    end
  end
end
