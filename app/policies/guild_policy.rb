# frozen_string_literal: true

class GuildPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  def apply?
    user&.verified_for_social_features?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
