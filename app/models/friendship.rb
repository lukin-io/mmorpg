# frozen_string_literal: true

class Friendship < ApplicationRecord
  STATUSES = {
    pending: 0,
    accepted: 1,
    rejected: 2,
    blocked: 3
  }.freeze

  enum :status, STATUSES

  belongs_to :requester, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :requester_id, uniqueness: {scope: :receiver_id}
  validate :disallow_self_friendship

  scope :for_user, ->(user) { where(requester: user).or(where(receiver: user)) }

  def accept!
    update!(status: :accepted, accepted_at: Time.current)
  end

  def decline!
    update!(status: :rejected)
  end

  private

  def disallow_self_friendship
    errors.add(:receiver_id, "cannot be the same as requester") if requester_id == receiver_id
  end
end
