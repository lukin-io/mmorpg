class CreateSocialStructures < ActiveRecord::Migration[8.1]
  def change
    create_table :group_listings do |t|
      t.string :title, null: false
      t.text :description
      t.integer :listing_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.references :owner, null: false, foreign_key: {to_table: :users}
      t.references :guild, foreign_key: true
      t.references :profession, foreign_key: true
      t.jsonb :requirements, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :group_listings, :listing_type
    add_index :group_listings, :status

    create_table :social_hubs do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :hub_type, null: false
      t.references :zone, foreign_key: true
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :social_hubs, :slug, unique: true

    create_table :social_hub_events do |t|
      t.references :social_hub, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.integer :status, null: false, default: 0
      t.string :host_npc_name
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :social_hub_events, :status
    add_index :social_hub_events, :starts_at
  end
end
