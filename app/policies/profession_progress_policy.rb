# frozen_string_literal: true

class ProfessionProgressPolicy < ApplicationPolicy
  def update_progress?
    record.user == user
  end

  alias_method :update?, :update_progress?

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end

