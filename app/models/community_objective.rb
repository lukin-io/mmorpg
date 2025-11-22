# frozen_string_literal: true

class CommunityObjective < ApplicationRecord
  enum :status, {
    tracking: 0,
    completed: 1,
    failed: 2
  }

  belongs_to :event_instance

  validates :title, :resource_key, presence: true

  def progress_ratio
    return 0 if goal_amount.zero?

    current_amount.to_f / goal_amount
  end
end
