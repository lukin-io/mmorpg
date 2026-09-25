# frozen_string_literal: true

class ReseedAshenOutdoorDustChanter < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/outdoor_npcs.rb")
    return unless File.exist?(path)

    say_with_time "reseed outdoor NPCs including veil_dust_chanter" do
      load path
    end
  end

  def down
  end
end
