# frozen_string_literal: true

# MovementCommand stores queued, server-authoritative movement intents per character.
class MovementCommand < ApplicationRecord
  DIRECTIONS = %w[north south east west].freeze

  enum :status, {
    queued: 0,
    processing: 1,
    processed: 2,
    failed: 3
  }

  belongs_to :character
  belongs_to :zone

  validates :direction, inclusion: {in: DIRECTIONS}

  scope :pending, -> { queued.order(:created_at) }

  def predicted_position
    return unless predicted_x && predicted_y

    [predicted_x, predicted_y]
  end
end
