class AddCombatInjuriesAndTreatments < ActiveRecord::Migration[8.1]
  def change
    create_table :character_injuries do |t|
      t.references :character, null: false, foreign_key: true
      t.references :arena_match, foreign_key: true
      t.string :severity, null: false
      t.string :name, null: false
      t.integer :stat_penalty_percent, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :healed_at
      t.timestamps
    end
    add_index :character_injuries, [:arena_match_id, :character_id], unique: true
    add_check_constraint :character_injuries, "severity IN ('light','medium','heavy','combat')", name: "injury_severity"
    add_check_constraint :character_injuries, "stat_penalty_percent BETWEEN 0 AND 90", name: "injury_penalty"
    create_table :injury_treatments do |t|
      t.references :character_injury, null: false, foreign_key: true
      t.references :healer, null: false, foreign_key: {to_table: :characters}
      t.references :inventory_item, foreign_key: true
      t.integer :price, null: false, default: 0
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_check_constraint :injury_treatments, "price >= 0 AND price <= 7000", name: "treatment_price"
    add_check_constraint :injury_treatments, "status IN ('pending','completed','declined')", name: "treatment_status"
    add_index :injury_treatments, [:character_injury_id, :healer_id], unique: true,
      where: "status = 'pending'", name: "one_pending_injury_treatment"
  end
end
