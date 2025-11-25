# frozen_string_literal: true

class GuildRank < ApplicationRecord
  DEFAULT_PERMISSIONS = {
    invite: false,
    kick: false,
    manage_bank: false,
    post_bulletins: false,
    start_war: false
  }.freeze

  belongs_to :guild

  after_initialize :apply_default_permissions, if: :new_record?

  validates :name, presence: true
  validates :position, presence: true, numericality: {greater_than_or_equal_to: 0}

  scope :ordered, -> { order(position: :asc) }

  def allows?(permission)
    permissions.fetch(permission.to_s, false)
  end

  def self.for_guild(guild)
    where(guild:).ordered
  end

  private

  def apply_default_permissions
    self.permissions = DEFAULT_PERMISSIONS.merge(permissions || {})
  end
end
