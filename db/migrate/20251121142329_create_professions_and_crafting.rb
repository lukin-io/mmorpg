class CreateProfessionsAndCrafting < ActiveRecord::Migration[8.1]
  def change
    create_table :professions do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.text :description
      t.boolean :gathering, null: false, default: false
      t.timestamps
    end
    add_index :professions, :name, unique: true

    create_table :profession_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :profession, null: false, foreign_key: true
      t.integer :skill_level, null: false, default: 1
      t.bigint :experience, null: false, default: 0
      t.integer :mastery_tier, null: false, default: 0
      t.timestamps
    end
    add_index :profession_progresses, [:user_id, :profession_id], unique: true, name: "index_profession_progresses_on_user_and_profession"

    create_table :recipes do |t|
      t.references :profession, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :tier, null: false, default: 1
      t.integer :duration_seconds, null: false, default: 60
      t.string :output_item_name, null: false
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :rewards, null: false, default: {}
      t.timestamps
    end

    create_table :crafting_stations do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :station_type, null: false
      t.integer :capacity, null: false, default: 5
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :crafting_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.references :crafting_station, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :completes_at, null: false
      t.jsonb :result_payload, null: false, default: {}
      t.timestamps
    end
  end
end
