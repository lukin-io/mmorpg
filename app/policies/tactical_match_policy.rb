# frozen_string_literal: true

class TacticalMatchPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (participant? || record.completed? || record.forfeited?)
  end

  def create?
    user.present? && user.character.present?
  end

  def join?
    user.present? && user.character.present? &&
      record.pending? && record.opponent.nil? &&
      record.creator != user.character
  end

  def play?
    user.present? && participant? && record.active?
  end

  private

  def participant?
    record.creator == user.character || record.opponent == user.character
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
