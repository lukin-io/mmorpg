# frozen_string_literal: true

# Adds passive_skills JSONB column to characters for leveled passive abilities.
#
# Passive skills are abilities that level from 0-100 and provide ongoing bonuses.
# Example: { "wanderer" => 50, "endurance" => 25 }
#
# Skills are defined in Game::Skills::PassiveSkillRegistry.
class AddPassiveSkillsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :passive_skills, :jsonb, null: false, default: {}
  end
end
