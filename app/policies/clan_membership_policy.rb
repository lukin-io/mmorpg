# frozen_string_literal: true

class ClanMembershipPolicy < ApplicationPolicy
  def destroy?
    record.user == user ||
      record.clan.leader == user ||
      user&.has_any_role?(:gm, :admin) ||
      permission_matrix.allows?(:manage_recruitment)
  end

  private

  def permission_matrix
    @permission_matrix ||= Clans::PermissionMatrix.new(
      clan: record.clan,
      membership: record.clan.clan_memberships.find_by(user: user)
    )
  end
end
