# frozen_string_literal: true

class GuildApplication < ApplicationRecord
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  belongs_to :guild
  belongs_to :applicant, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :answers, presence: true

  scope :pending_review, -> { where(status: :pending) }

  def approve!(reviewer:)
    update!(status: :approved, reviewed_by: reviewer, reviewed_at: Time.current)
  end

  def reject!(reviewer:)
    update!(status: :rejected, reviewed_by: reviewer, reviewed_at: Time.current)
  end
end
