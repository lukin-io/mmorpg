# frozen_string_literal: true

class IgnoreListEntryPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def destroy?
    record.user == user
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
