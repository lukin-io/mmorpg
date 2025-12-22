# frozen_string_literal: true

# Add NPC support to arena applications and participations
# This allows arena bots to create fight applications that players can accept
class AddNpcSupportToArena < ActiveRecord::Migration[8.1]
  def change
    # Allow NPC to be applicant (alternative to character)
    add_reference :arena_applications, :npc_template, foreign_key: true, null: true

    # Make applicant_id nullable for NPC applications
    change_column_null :arena_applications, :applicant_id, true

    # Allow NPC to be participant (alternative to character)
    add_reference :arena_participations, :npc_template, foreign_key: true, null: true

    # Make character_id nullable for NPC participants
    change_column_null :arena_participations, :character_id, true

    # Index for finding NPC applications efficiently
    add_index :arena_applications, [:arena_room_id, :npc_template_id],
      where: "npc_template_id IS NOT NULL",
      name: "idx_arena_apps_npc"
  end
end
