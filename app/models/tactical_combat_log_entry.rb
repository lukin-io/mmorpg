# frozen_string_literal: true

class TacticalCombatLogEntry < ApplicationRecord
  belongs_to :tactical_match

  validates :message, presence: true

  default_scope { order(:round_number, :sequence) }
end
