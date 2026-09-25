# frozen_string_literal: true

# Ensures healer bags, ash herbs, and combat scrolls exist after deploy.
class EnsureAshenHealerTemplates < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(Game::Professions::Templates)

    Game::Professions::Templates.ensure_craft_items!
  end

  def down
  end
end
