# frozen_string_literal: true

class QuestPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def accept?
    user.present?
  end

  def advance_story?
    user.present?
  end

  def complete?
    user.present?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
