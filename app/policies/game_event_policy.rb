# frozen_string_literal: true

class GameEventPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    index?
  end

  def update?
    user&.has_any_role?(:gm, :admin)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
