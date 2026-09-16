# frozen_string_literal: true

class CreateArenaApplicationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :arena_application_memberships do |t|
      t.references :arena_application, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.string :team, null: false
      t.timestamps
    end
    add_index :arena_application_memberships, [:arena_application_id, :character_id],
      unique: true, name: "index_arena_memberships_on_application_and_character"
    add_check_constraint :arena_application_memberships, "team IN ('a', 'b')",
      name: "arena_membership_team"
  end
end
