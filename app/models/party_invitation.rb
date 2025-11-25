# frozen_string_literal: true

class PartyInvitation < ApplicationRecord
  STATUSES = {
    pending: 0,
    accepted: 1,
    declined: 2,
    expired: 3
  }.freeze

  enum :status, STATUSES

  belongs_to :party
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  before_validation :assign_token, on: :create

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { pending.where("expires_at > ?", Time.current) }

  def accept!
    update!(status: :accepted)
    return if party.party_memberships.exists?(user: recipient)

    party.party_memberships.create!(
      user: recipient,
      role: :member,
      status: :active,
      ready_state: :unknown,
      joined_at: Time.current
    )
  end

  def reject!
    update!(status: :declined)
  end

  private

  def assign_token
    self.token ||= SecureRandom.hex(10)
  end
end
