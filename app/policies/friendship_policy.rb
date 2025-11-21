# frozen_string_literal: true

class FriendshipPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  def update?
    participant?
  end

  def destroy?
    participant?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.for_user(user)
    end
  end

  private

  def participant?
    return false unless user && record

    record.requester == user || record.receiver == user
  end
end
