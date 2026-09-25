# frozen_string_literal: true

class RebalanceAshenThematicSets < ActiveRecord::Migration[8.1]
  def up
    path = Rails.root.join("db/seeds/ashen_veil_thematic_sets.rb")
    raise "Missing thematic set seed: #{path}" unless File.exist?(path)

    say_with_time "rebalance Ashen Veil thematic set stats" do
      load path
    end
  end

  def down
  end
end
