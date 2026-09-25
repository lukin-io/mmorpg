# frozen_string_literal: true

class IdleTickControl < ApplicationRecord
  validates :tick_ms, numericality: {greater_than_or_equal_to: 15_000, less_than_or_equal_to: 600_000}
  validates :batch_size, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 200}
end
