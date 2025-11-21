# frozen_string_literal: true

class CompetitionBracketPolicy < ApplicationPolicy
  def show?
    user.present?
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
