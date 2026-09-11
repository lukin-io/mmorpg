class CreateCharacterLicenses < ActiveRecord::Migration[8.1]
  def change
    create_table :character_licenses do |t|
      t.references :character, null: false, foreign_key: true
      t.references :item_template, null: false, foreign_key: true
      t.references :world_action_offer, null: false, foreign_key: true, index: {unique: true}
      t.string :kind, null: false
      t.integer :tier, null: false
      t.string :name, null: false
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :character_licenses, [:character_id, :kind, :expires_at]
    add_check_constraint :character_licenses, "kind IN ('trading', 'doctor')", name: "character_licenses_known_kind"
    add_check_constraint :character_licenses, "tier BETWEEN 1 AND 3", name: "character_licenses_known_tier"
    add_check_constraint :character_licenses, "expires_at > starts_at", name: "character_licenses_positive_interval"
  end
end
