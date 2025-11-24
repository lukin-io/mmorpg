class AddUpkeepToHousingPlots < ActiveRecord::Migration[8.1]
  def change
    change_table :housing_plots, bulk: true do |t|
      t.integer :upkeep_gold_cost, null: false, default: 200
      t.datetime :next_upkeep_due_at
    end
  end
end
