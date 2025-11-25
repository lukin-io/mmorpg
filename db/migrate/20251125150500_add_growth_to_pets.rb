# frozen_string_literal: true

class AddGrowthToPets < ActiveRecord::Migration[8.1]
  def change
    change_table :pet_companions, bulk: true do |t|
      t.integer :bonding_experience, null: false, default: 0
      t.string :affinity_stage, null: false, default: "neutral"
      t.jsonb :care_state, null: false, default: {}
      t.datetime :last_care_performed_at
      t.datetime :care_task_available_at
      t.string :passive_bonus_type
      t.integer :passive_bonus_value, null: false, default: 0
      t.integer :gathering_bonus, null: false, default: 0
    end
    add_index :pet_companions, :affinity_stage
  end
end
