# frozen_string_literal: true

# CombatLogEntry persists deterministic battle logs for later review or moderation.
class CombatLogEntry < ApplicationRecord
  belongs_to :battle

  default_scope { order(:round_number, :sequence) }

  validates :message, presence: true
end
