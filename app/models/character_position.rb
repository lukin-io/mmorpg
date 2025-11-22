# frozen_string_literal: true

# Tracks the authoritative tile location/state for a character inside a zone.
class CharacterPosition < ApplicationRecord
  enum :state, {
    active: 0,
    downed: 1,
    respawning: 2
  }

  belongs_to :character
  belongs_to :zone

  validates :x, :y, numericality: {only_integer: true}
  validates :last_turn_number, numericality: {greater_than_or_equal_to: 0}

  def ready_for_action?(cooldown_seconds:)
    active? && (last_action_at.nil? || last_action_at <= cooldown_seconds.seconds.ago)
  end
end
