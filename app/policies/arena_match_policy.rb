# frozen_string_literal: true

class ArenaMatchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
