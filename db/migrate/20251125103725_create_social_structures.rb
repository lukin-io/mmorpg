class CreateSocialStructures < ActiveRecord::Migration[8.1]
  def change
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
