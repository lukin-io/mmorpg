# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    moderator_or_higher?
  end

  def show?
    moderator_or_higher? || user == record
  end

  def update?
    gm_or_higher?
  end

  def destroy?
    user&.has_role?(:admin)
  end

  def audit?
    gm_or_higher?
  end

  class Scope < Scope
    def resolve
      if user&.has_role?(:admin)
        scope.all
      elsif user&.has_any_role?(:gm, :moderator)
        scope.where.not(id: nil)
      else
        scope.none
      end
    end
  end

  private

  def moderator_or_higher?
    user&.has_any_role?(:moderator, :gm, :admin)
  end

  def gm_or_higher?
    user&.has_any_role?(:gm, :admin)
  end
end
