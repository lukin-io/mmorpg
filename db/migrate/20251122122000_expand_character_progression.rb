# frozen_string_literal: true

class ExpandCharacterProgression < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :stat_points_available, :integer, null: false, default: 0
    add_column :characters, :skill_points_available, :integer, null: false, default: 0
    add_column :characters, :allocated_stats, :jsonb, null: false, default: {}
    add_column :characters, :reputation, :integer, null: false, default: 0
    add_column :characters, :faction_alignment, :string, null: false, default: "neutral"
    add_column :characters, :alignment_score, :integer, null: false, default: 0
    add_column :characters, :resource_pools, :jsonb, null: false, default: {}
    add_column :characters, :last_level_up_at, :datetime
  end
end
