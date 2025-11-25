# frozen_string_literal: true

class MountStableSlot < ApplicationRecord
  enum :status, {
    locked: "locked",
    unlocked: "unlocked",
    active: "active"
  }

  belongs_to :user
  belongs_to :current_mount, class_name: "Mount", optional: true

  validates :slot_index, numericality: {greater_than_or_equal_to: 0}

  scope :available, -> { where(status: [:unlocked, :active]) }
end
