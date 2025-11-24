# frozen_string_literal: true

class GuildMission < ApplicationRecord
  enum :status, {
    pending: 0,
    active: 1,
    completed: 2
  }

  belongs_to :guild
  belongs_to :required_profession, class_name: "Profession"

  validates :required_item_name, presence: true
  validates :required_quantity, numericality: {greater_than: 0}
  validates :progress_quantity, numericality: {greater_than_or_equal_to: 0}

  scope :incomplete, -> { where.not(status: :completed) }

  def remaining_quantity
    [required_quantity - progress_quantity, 0].max
  end

  def apply_progress!(amount)
    new_progress = progress_quantity + amount
    new_status = new_progress >= required_quantity ? :completed : status
    update!(progress_quantity: [new_progress, required_quantity].min, status: new_status)
  end
end
