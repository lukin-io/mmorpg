# frozen_string_literal: true

class DungeonInstancePolicy < ApplicationPolicy
  def show?
    user.present? && party_member?
  end

  def play?
    user.present? && party_member? && record.active?
  end

  private

  def party_member?
    record.party.party_memberships.exists?(user: user, status: :active)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(party: :party_memberships)
        .where(party_memberships: {user_id: user.id, status: :active})
    end
  end
end
