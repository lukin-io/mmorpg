# frozen_string_literal: true

class RenameOutpostZoneToAshenShore < ActiveRecord::Migration[8.1]
  OLD_NAME = "Outpost Surroundings"
  NEW_NAME = "Пепельный Берег"

  ZONE_TABLES = {
    "map_tile_templates" => "zone",
    "tile_npcs" => "zone",
    "tile_buildings" => "zone"
  }.freeze

  def up
    say_with_time "rename outdoor zone #{OLD_NAME.inspect} -> #{NEW_NAME.inspect}" do
      rename_zone_row!
      ZONE_TABLES.each do |table, column|
        next unless table_exists?(table) && column_exists?(table, column)

        execute(sanitize_sql_array([
          "UPDATE #{table} SET #{column} = ? WHERE #{column} = ?",
          NEW_NAME,
          OLD_NAME
        ]))
      end
    end

    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    if File.exist?(path)
      say_with_time "reseed outdoor NPCs after zone rename" do
        load path
      end
    end
  end

  def down
    say_with_time "rename outdoor zone #{NEW_NAME.inspect} -> #{OLD_NAME.inspect}" do
      if table_exists?("zones")
        execute(sanitize_sql_array([
          "UPDATE zones SET name = ? WHERE name = ?",
          OLD_NAME,
          NEW_NAME
        ]))
      end
      ZONE_TABLES.each do |table, column|
        next unless table_exists?(table) && column_exists?(table, column)

        execute(sanitize_sql_array([
          "UPDATE #{table} SET #{column} = ? WHERE #{column} = ?",
          OLD_NAME,
          NEW_NAME
        ]))
      end
    end
  end

  private

  def rename_zone_row!
    return unless table_exists?("zones")

    execute(sanitize_sql_array([
      "UPDATE zones SET name = ? WHERE name = ? AND NOT EXISTS (SELECT 1 FROM zones z2 WHERE z2.name = ?)",
      NEW_NAME,
      OLD_NAME,
      NEW_NAME
    ]))

    execute(sanitize_sql_array([
      "DELETE FROM zones WHERE name = ?",
      OLD_NAME
    ]))
  end

  def sanitize_sql_array(array)
    ActiveRecord::Base.sanitize_sql_array(array)
  end
end
