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
  belongs_to :guild_rank, optional: true

  validates :guild_id, uniqueness: {scope: :user_id}

  scope :with_role, ->(role_name) { where(role: roles[role_name]) }

  after_commit :sync_user_characters
  before_validation :assign_default_rank, on: :create

  delegate :allows?, to: :guild_rank, prefix: true, allow_nil: true

  def can?(permission)
    guild_rank_allows?(permission)
  end

  private

  def sync_user_characters
    user&.sync_character_memberships!
  end

  def assign_default_rank
    return if guild_rank.present?

    self.guild_rank = guild&.default_rank
  end
end
