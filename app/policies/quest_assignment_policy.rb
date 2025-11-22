# frozen_string_literal: true

class QuestAssignmentPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def daily?
    user.present?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.joins(:character).where(characters: {user_id: user.id})
    end
  end
end
