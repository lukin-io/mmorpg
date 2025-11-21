# frozen_string_literal: true

class MailMessagePolicy < ApplicationPolicy
  def index?
    user&.verified_for_social_features?
  end

  def show?
    participant?
  end

  def create?
    user&.verified_for_social_features?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(sender: user).or(scope.where(recipient: user))
    end
  end

  private

  def participant?
    return false unless user && record

    record.sender == user || record.recipient == user
  end
end
