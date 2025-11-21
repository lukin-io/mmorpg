class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :announcements, :created_at
  end
end
