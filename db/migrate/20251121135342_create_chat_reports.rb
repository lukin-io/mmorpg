class CreateChatReports < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_reports do |t|
      t.references :chat_message, null: true, foreign_key: true
      t.references :reporter, null: false, foreign_key: {to_table: :users}
      t.text :reason, null: false
      t.jsonb :evidence, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.timestamps
    end

    add_index :chat_reports, :status
  end
end
