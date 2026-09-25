# frozen_string_literal: true

# Reseeds outdoor NPCs so gate-adjacent starter fights appear after deploy.
class ReseedAshenOutdoorGateNpcs < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    load path if File.exist?(path)
  end

  def down
  end
end
