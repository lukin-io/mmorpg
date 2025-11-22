class CreateEventInstancesAndTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :event_instances do |t|
      t.references :game_event, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.string :announcer_npc_key
      t.jsonb :temporary_npc_keys, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :event_instances, [:game_event_id, :starts_at]

    create_table :arena_tournaments do |t|
      t.references :event_instance, null: false, foreign_key: true
      t.references :competition_bracket, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.string :announcer_npc_key
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :community_objectives do |t|
      t.references :event_instance, null: false, foreign_key: true
      t.string :title, null: false
      t.string :resource_key, null: false
      t.integer :goal_amount, null: false, default: 0
      t.integer :current_amount, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :community_objectives, [:event_instance_id, :resource_key], name: "index_objectives_on_event_and_resource"
  end
end
