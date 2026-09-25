# frozen_string_literal: true

class ExpandClansTreasuryInvitesAndRoles < ActiveRecord::Migration[8.0]
  def change
    change_table :clans, bulk: true do |t|
      t.string :alignment, null: false, default: "none"
      t.string :icon_path
      t.boolean :treasury_locked, null: false, default: true
      t.decimal :treasury_nv, precision: 12, scale: 2, null: false, default: 0
    end

    create_table :clan_treasury_items do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :item_template, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.references :deposited_by_character, foreign_key: {to_table: :characters}, null: true
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clan_treasury_items, [:clan_id, :item_template_id]

    create_table :clan_invitations do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :inviter_character, null: false, foreign_key: {to_table: :characters}
      t.references :invitee_character, null: false, foreign_key: {to_table: :characters}
      t.string :status, null: false, default: "pending"
      t.datetime :responded_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clan_invitations, [:invitee_character_id, :status]
    add_index :clan_invitations, [:clan_id, :invitee_character_id, :status],
      name: "index_clan_invites_unique_pending",
      unique: true,
      where: "status = 'pending'"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE clan_memberships SET role = 'deputy' WHERE role = 'officer';
          UPDATE clan_memberships SET role = 'worker' WHERE role = 'member';
        SQL
      end
      dir.down do
        execute <<~SQL.squish
          UPDATE clan_memberships SET role = 'officer' WHERE role = 'deputy';
          UPDATE clan_memberships SET role = 'member' WHERE role IN ('worker', 'treasurer');
        SQL
      end
    end
  end
end
