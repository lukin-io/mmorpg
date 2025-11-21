# frozen_string_literal: true

class MountPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
