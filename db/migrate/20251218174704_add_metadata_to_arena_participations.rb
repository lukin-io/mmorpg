# frozen_string_literal: true

# Add metadata column to arena_participations for NPC HP tracking
# Also make user_id nullable since NPC participants don't have users
class AddMetadataToArenaParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :arena_participations, :metadata, :jsonb, default: {}, null: false
    add_column :arena_participations, :ended_at, :datetime

    # Make user_id nullable for NPC participants
    change_column_null :arena_participations, :user_id, true
  end
end
