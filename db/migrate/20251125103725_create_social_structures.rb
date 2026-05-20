class CreateSocialStructures < ActiveRecord::Migration[8.1]
  def change
    create_table :group_listings do |t|
      t.string :title, null: false
      t.text :description
      t.integer :listing_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.references :owner, null: false, foreign_key: {to_table: :users}
      t.references :clan, foreign_key: true
      t.references :profession, foreign_key: true
      t.jsonb :requirements, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :group_listings, :listing_type
    add_index :group_listings, :status

    create_table :ignore_list_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ignored_user, null: false, foreign_key: {to_table: :users}
      t.string :context
      t.string :notes
      t.timestamps
    end

    add_index :ignore_list_entries, [:user_id, :ignored_user_id],
      unique: true,
      name: "index_ignore_entries_on_user_and_target"
  end
end
