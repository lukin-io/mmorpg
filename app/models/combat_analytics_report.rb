# frozen_string_literal: true

class CombatAnalyticsReport < ApplicationRecord
  belongs_to :battle

  validates :generated_at, presence: true
end
