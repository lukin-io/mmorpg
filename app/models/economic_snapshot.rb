# frozen_string_literal: true

# EconomicSnapshot captures daily economy metrics for dashboards and analytics.
class EconomicSnapshot < ApplicationRecord
  validates :captured_on, presence: true, uniqueness: true

  scope :recent_first, -> { order(captured_on: :desc) }
end
