class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships do |t|
      t.references :requester, null: false, foreign_key: {to_table: :users}
      t.references :receiver, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :friendships, [:requester_id, :receiver_id], unique: true
  end
end
