# frozen_string_literal: true

class PartyMembership < ApplicationRecord
  ROLES = {
    member: 0,
    leader: 1,
    tank: 2,
    healer: 3,
    damage: 4
  }.freeze

  READY_STATES = {
    unknown: 0,
    ready: 1,
    not_ready: 2
  }.freeze

  STATUSES = {
    active: 0,
    benched: 1,
    left: 2
  }.freeze

  enum :role, ROLES
  enum :ready_state, READY_STATES
  enum :status, STATUSES

  belongs_to :party
  belongs_to :user

  validates :user_id, uniqueness: {scope: :party_id}

  scope :active, -> { where(status: STATUSES[:active]) }

  def ready?
    ready_state == "ready"
  end
end
