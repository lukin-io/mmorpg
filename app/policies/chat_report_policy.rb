# frozen_string_literal: true

class ChatReportPolicy < ApplicationPolicy
  def index?
    moderator_or_higher?
  end

  def create?
    user&.verified_for_social_features?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.has_any_role?(:moderator, :gm, :admin)
        scope.all
      else
        scope.where(reporter: user)
      end
    end
  end

  private

  def moderator_or_higher?
    user&.has_any_role?(:moderator, :gm, :admin)
  end
end
