# frozen_string_literal: true

# Adds separate skill point pools for combat and peace skills.
#
# Design:
# - Combat skill points: Used for combat, magic, and resistance skills
# - Peace skill points: Used for crafting, gathering, and social skills
#
# Existing skill_points_available is kept for backward compatibility and
# can be used as a unified pool or deprecated later.
class AddSkillPointPoolsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :combat_skill_points, :integer, null: false, default: 0
    add_column :characters, :peace_skill_points, :integer, null: false, default: 0

    # Add index for querying characters with available skill points
    add_index :characters, :combat_skill_points, where: "combat_skill_points > 0"
    add_index :characters, :peace_skill_points, where: "peace_skill_points > 0"

    reversible do |dir|
      dir.up do
        # Migrate existing skill_points_available to combat_skill_points
        # This is a reasonable default - players can then allocate to peace skills
        execute <<-SQL.squish
          UPDATE characters
          SET combat_skill_points = skill_points_available
          WHERE skill_points_available > 0
        SQL
      end
    end
  end
end
