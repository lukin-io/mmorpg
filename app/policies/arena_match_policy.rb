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

  # Submit a complete combat turn or surrender intent.
  # Only participants can submit actions
  def action?
    return false unless user.present?
    return false unless record.live?

    record.arena_participations.exists?(user: user)
  end

  def claim_timeout?
    action?
  end

  def finish?
    return false unless user.present?

    record.arena_participations.exists?(user: user)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
