# frozen_string_literal: true

# Reseed outdoor NPCs so ash_herb drops appear near the west gate.
class ReseedAshenOutdoorHerbDrops < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load path if File.exist?(path)
  end

  def down
  end
end
