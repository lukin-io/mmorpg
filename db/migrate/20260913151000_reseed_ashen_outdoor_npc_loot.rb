# frozen_string_literal: true

# Reseeds outdoor NPCs so shore loot includes craft mats after deploy.
class ReseedAshenOutdoorNpcLoot < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load path if File.exist?(path)
  end

  def down
  end
end
