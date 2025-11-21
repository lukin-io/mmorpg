# frozen_string_literal: true

class TradeSessionPolicy < ApplicationPolicy
  def show?
    participant?
  end

  def create?
    user&.verified_for_social_features?
  end

  def update?
    participant?
  end

  class Scope < Scope
    def resolve
      scope.where(initiator: user).or(scope.where(recipient: user))
    end
  end

  private

  def participant?
    record&.initiator == user || record&.recipient == user
  end
end

