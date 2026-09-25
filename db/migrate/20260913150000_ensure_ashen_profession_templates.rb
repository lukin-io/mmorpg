# frozen_string_literal: true

# Ensures Ashen craft item templates exist after deploy.
class EnsureAshenProfessionTemplates < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(Game::Professions::Templates)

    Game::Professions::Templates.ensure_craft_items!
    say "ensured ashen profession craft templates"
  end

  def down
  end
end
