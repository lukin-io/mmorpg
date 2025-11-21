# frozen_string_literal: true

class HousingPlotPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    record.user == user || user&.has_any_role?(:gm, :admin)
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
