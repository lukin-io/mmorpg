# frozen_string_literal: true

# BattleParticipant stores combatants (characters or NPC templates) in a battle.
class BattleParticipant < ApplicationRecord
  belongs_to :battle
  belongs_to :character, optional: true
  belongs_to :npc_template, optional: true

  validates :role, :team, presence: true
  validates :hp_remaining, :initiative, numericality: {greater_than_or_equal_to: 0}

  def combatant_name
    character&.name || npc_template&.name || "Unknown"
  end
end

