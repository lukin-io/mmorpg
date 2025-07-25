class CreateGuilds < ActiveRecord::Migration[8.0]
  def change
    drop_table :guilds
    create_table :guilds do |t|
      t.string :name
      t.text :description
      # t.references :leader, null: false, foreign_key: true
      t.references :leader, null: false, foreign_key: { to_table: :characters }

      t.timestamps
    end
  end
end
