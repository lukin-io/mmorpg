# frozen_string_literal: true

# Persistent medical effect. Expiry changes the effective projection without
# destroying fight history; treatment records the actual healing timestamp.
class CharacterInjury < ApplicationRecord
  belongs_to :character
  belongs_to :arena_match, optional: true
  has_many :injury_treatments, dependent: :restrict_with_error

  SEVERITIES = %w[light medium heavy combat].freeze
  validates :severity, inclusion: {in: SEVERITIES}
  validates :name, :expires_at, presence: true
  validates :stat_penalty_percent, numericality: {only_integer: true, in: 0..90}
  scope :active_at, ->(at) { where(healed_at: nil).where("expires_at > ?", at) }

  def active?(at: Time.current)
    healed_at.nil? && expires_at > at
  end

  def blocks_movement?
    active? && severity.in?(%w[heavy combat])
  end
end
