# frozen_string_literal: true

class ClanMembership < ApplicationRecord
  belongs_to :clan
  belongs_to :character

  validates :role, inclusion: {in: Clan::ROLES}
  validates :character_id, uniqueness: true
  validates :joined_at, presence: true

  before_validation on: :create do
    self.joined_at ||= Time.current
  end
end
