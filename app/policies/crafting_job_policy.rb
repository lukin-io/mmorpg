# frozen_string_literal: true

class CraftingJobPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end

