# frozen_string_literal: true

# ClanRolePermission stores per-clan overrides for what each membership role
# can do (invite, withdraw, declare war, etc.). Controllers query it through
# Clans::PermissionMatrix to toggle UI capabilities without hardcoding rules.
#
# Usage:
#   clan.clan_role_permissions.create!(role: :officer, permission_key: "manage_treasury", enabled: true)
#   Clans::PermissionMatrix.new(clan:, membership: membership).allows?(:manage_treasury)
class ClanRolePermission < ApplicationRecord
  enum :role, ClanMembership.roles

  belongs_to :clan

  validates :role, presence: true
  validates :permission_key, presence: true
  validates :permission_key, uniqueness: {scope: [:clan_id, :role]}

  scope :for_permission, ->(key) { where(permission_key: key.to_s) }
end
