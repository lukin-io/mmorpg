# frozen_string_literal: true

class ClanMembership < ApplicationRecord
  enum :role, {
    member: 0,
    officer: 1,
    warlord: 2,
    quartermaster: 3,
    leader: 4,
    recruiter: 5
  }

  belongs_to :clan
  belongs_to :user

  validates :clan_id, uniqueness: {scope: :user_id}

  after_commit :sync_user_characters

  def permission_matrix
    Clans::PermissionMatrix.new(clan:, membership: self)
  end

  private

  def sync_user_characters
    user&.sync_character_memberships!
  end
end
