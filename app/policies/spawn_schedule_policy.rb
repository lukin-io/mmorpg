# frozen_string_literal: true

class SpawnSchedulePolicy < ApplicationPolicy
  def index?
    moderator?
  end

  def create?
    moderator?
  end

  def update?
    moderator?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.moderator?

      scope.all
    end
  end

  private

  def moderator?
    user&.moderator?
  end
end
