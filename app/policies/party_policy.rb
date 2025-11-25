# frozen_string_literal: true

class PartyPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    member?
  end

  def create?
    user.present?
  end

  def manage?
    record.leader == user
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.joins(:party_memberships).where(party_memberships: {user_id: user.id}).distinct
    end
  end

  private

  def member?
    return false unless user

    record.party_memberships.exists?(user:)
  end
end
