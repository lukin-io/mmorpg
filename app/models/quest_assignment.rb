# frozen_string_literal: true

class QuestAssignment < ApplicationRecord
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2,
    failed: 3,
    expired: 4
  }

  belongs_to :quest
  belongs_to :character

  validates :status, presence: true

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
