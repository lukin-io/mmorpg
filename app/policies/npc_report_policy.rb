# frozen_string_literal: true

class NpcReportPolicy < ApplicationPolicy
  def new?
    user.present?
  end

  def create?
    user.present?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.moderator?

      scope.all
    end
  end
end
