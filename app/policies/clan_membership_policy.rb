# frozen_string_literal: true

class ClanMembershipPolicy < ApplicationPolicy
  def destroy?
    record.user == user || record.clan.leader == user || user&.has_any_role?(:gm, :admin)
  end
end
