# frozen_string_literal: true

class ReseedAshenOutdoorScout < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    return unless File.exist?(path)

    say_with_time "reseed outdoor NPCs including ash_shore_scout" do
      load path
    end
  end

  def down
  end
end
