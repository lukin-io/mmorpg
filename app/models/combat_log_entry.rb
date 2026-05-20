# frozen_string_literal: true

# CombatLogEntry persists deterministic Neverlands-style fight events for
# public logs, statistics, and moderation review.
class CombatLogEntry < ApplicationRecord
  belongs_to :battle, optional: true
  belongs_to :arena_match, optional: true
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :target, polymorphic: true, optional: true

  default_scope { order(:round_number, :sequence) }

  before_validation :set_occurred_at

  validates :message, presence: true
  validates :log_type, presence: true
  validate :has_exactly_one_fight_owner

  scope :damage, -> { where("damage_amount > 0") }
  scope :healing, -> { where("healing_amount > 0") }
  scope :by_actor, ->(actor_id) { where(actor_id:) if actor_id.present? }
  scope :for_fight, ->(fight) do
    case fight
    when Battle then where(battle: fight)
    when ArenaMatch then where(arena_match: fight)
    else none
    end
  end

  def fight
    arena_match || battle
  end

  def occurred_at_or_created_at
    occurred_at || created_at
  end

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end

  def has_exactly_one_fight_owner
    owner_count = [battle_id, arena_match_id].count(&:present?)
    return if owner_count == 1

    errors.add(:base, "must belong to exactly one fight")
  end
end
