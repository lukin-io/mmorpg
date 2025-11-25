# frozen_string_literal: true

class MountPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    record.user == user
  end

  alias_method :assign_to_slot?, :update?
  alias_method :summon?, :update?

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
