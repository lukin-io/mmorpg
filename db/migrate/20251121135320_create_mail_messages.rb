class CreateMailMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :mail_messages do |t|
      t.references :sender, null: false, foreign_key: {to_table: :users}
      t.references :recipient, null: false, foreign_key: {to_table: :users}
      t.string :subject, null: false
      t.text :body, null: false
      t.jsonb :attachment_payload, null: false, default: {}
      t.datetime :delivered_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :read_at
      t.timestamps
    end

    add_index :mail_messages, [:recipient_id, :delivered_at]
  end
end
