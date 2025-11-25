# frozen_string_literal: true

class GroupListingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    record.owner == user
  end

  def destroy?
    record.owner == user
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
