# frozen_string_literal: true

class GuildMembership < ApplicationRecord
  enum :role, {
    member: 0,
    recruiter: 1,
    officer: 2,
    quartermaster: 3,
    warlord: 4,
    leader: 5
  }

  enum :status, {
    pending: 0,
    active: 1,
    suspended: 2
  }

  belongs_to :guild
  belongs_to :user

  validates :guild_id, uniqueness: {scope: :user_id}

  scope :with_role, ->(role_name) { where(role: roles[role_name]) }
end
