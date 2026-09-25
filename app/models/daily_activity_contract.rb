# frozen_string_literal: true

class DailyActivityContract < ApplicationRecord
  belongs_to :character

  validates :day_key, :contract_key, :kind, presence: true
  validates :target, :progress, numericality: {greater_than_or_equal_to: 0}
end
