# frozen_string_literal: true

# GameOverviewSnapshot stores a periodic rollup of engagement and monetization KPIs
# for the `/game_overview` landing page. Values are persisted so we can show
# historical deltas and avoid re-running expensive queries on every request.
class GameOverviewSnapshot < ApplicationRecord
  validates :captured_at, presence: true

  scope :recent_first, -> { order(captured_at: :desc) }

  def self.latest
    recent_first.first
  end

  def self.previous
    recent_first.offset(1).first
  end

  def value_for(attribute)
    public_send(attribute)
  end
end
