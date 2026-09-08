class CreateAirshipJourneys < ActiveRecord::Migration[8.1]
  def change
    create_table :airship_journeys do |t|
      t.references :character, null: false, foreign_key: true
      t.references :boarding_offer, null: false, foreign_key: {to_table: :world_action_offers}, index: {unique: true}
      t.references :source_zone, null: false, foreign_key: {to_table: :zones}
      t.references :destination_zone, null: false, foreign_key: {to_table: :zones}
      t.references :last_position_zone, null: false, foreign_key: {to_table: :zones}
      t.integer :source_x, null: false
      t.integer :source_y, null: false
      t.integer :destination_x, null: false
      t.integer :destination_y, null: false
      t.integer :last_position_x, null: false
      t.integer :last_position_y, null: false
      t.string :route_key, null: false
      t.string :route_label, null: false
      t.decimal :fare_nv, precision: 12, scale: 2, null: false
      t.datetime :boarded_at, null: false
      t.datetime :departs_at, null: false
      t.datetime :arrives_at, null: false
      t.datetime :disembarked_at
      t.string :error_message
      t.integer :status, null: false, default: 0
      t.jsonb :waypoints, null: false, default: []
      t.timestamps
    end
    add_index :airship_journeys, :character_id, unique: true, where: "status = 0", name: "index_one_aboard_airship_journey_per_character"
    add_index :airship_journeys, [:route_key, :departs_at], where: "status = 0", name: "index_aboard_airship_flight"
    add_check_constraint :airship_journeys, "fare_nv > 0", name: "airship_positive_fare"
    add_check_constraint :airship_journeys, "boarded_at <= departs_at AND departs_at < arrives_at", name: "airship_ordered_deadlines"
  end
end
