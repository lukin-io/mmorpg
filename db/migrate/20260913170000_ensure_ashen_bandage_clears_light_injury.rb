# frozen_string_literal: true

# Refresh craft consumable templates so bandages clear light injuries on live.
class EnsureAshenBandageClearsLightInjury < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(Game::Professions::Templates)

    Game::Professions::Templates.ensure_craft_items!
  end

  def down
  end
end
