# frozen_string_literal: true

# CombatLogEntry persists deterministic battle logs for later review or moderation.
class CombatLogEntry < ApplicationRecord
  belongs_to :battle
  belongs_to :ability, optional: true

  default_scope { order(:round_number, :sequence) }

  validates :message, presence: true

  scope :damage, -> { where("damage_amount > 0") }
  scope :healing, -> { where("healing_amount > 0") }
  scope :by_actor, ->(actor_id) { where(actor_id:) if actor_id.present? }
end
