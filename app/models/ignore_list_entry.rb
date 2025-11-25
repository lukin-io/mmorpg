# frozen_string_literal: true

class IgnoreListEntry < ApplicationRecord
  belongs_to :user
  belongs_to :ignored_user, class_name: "User"

  validates :ignored_user_id, uniqueness: {scope: :user_id}
  validate :prevent_self_ignore

  scope :for_user, ->(user) { where(user:) }

  private

  def prevent_self_ignore
    errors.add(:ignored_user_id, "cannot be yourself") if user_id == ignored_user_id
  end
end
