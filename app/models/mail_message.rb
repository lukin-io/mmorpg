# frozen_string_literal: true

class MailMessage < ApplicationRecord
  ATTACHMENT_KEYS = %w[item_name item_id currency amount notes].freeze

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :subject, presence: true, length: {maximum: 120}
  validates :body, presence: true
  validate :attachment_payload_is_hash

  scope :inbox_for, ->(user) { where(recipient: user).order(delivered_at: :desc) }
  scope :sent_by, ->(user) { where(sender: user).order(delivered_at: :desc) }

  def mark_read!
    update!(read_at: Time.current)
  end

  def read?
    read_at.present?
  end

  private

  def attachment_payload_is_hash
    return if attachment_payload.is_a?(Hash)

    errors.add(:attachment_payload, "must be a JSON object")
  end
end
