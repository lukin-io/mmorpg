# frozen_string_literal: true

class PartyPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
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

      scope.all
    end
  end

  private

  def member?
    record.party_memberships.exists?(user:)
  end
end
