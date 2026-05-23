# frozen_string_literal: true

# CombatLogEntry persists deterministic Neverlands-style fight events for
# public logs and fight statistics.
class CombatLogEntry < ApplicationRecord
  belongs_to :arena_match
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :target, polymorphic: true, optional: true

  default_scope { order(:round_number, :sequence) }

  before_validation :set_occurred_at

  validates :message, presence: true
  validates :log_type, presence: true

  scope :damage, -> { where("damage_amount > 0") }
  scope :by_actor, ->(actor_id) { where(actor_id:) if actor_id.present? }
  scope :for_fight, ->(fight) { fight.is_a?(ArenaMatch) ? where(arena_match: fight) : none }

  def fight
    arena_match
  end

  def occurred_at_or_created_at
    occurred_at || created_at
  end

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
