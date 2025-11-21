class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :status, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :purchases, :external_id, unique: true
  end
end
