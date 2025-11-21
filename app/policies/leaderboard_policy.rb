# frozen_string_literal: true

class LeaderboardPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def recalculate?
    user&.has_any_role?(:gm, :admin)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
