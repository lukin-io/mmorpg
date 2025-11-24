# frozen_string_literal: true

class ProfessionProgressPolicy < ApplicationPolicy
  def enroll?
    user.present?
  end

  def reset?
    record.user == user
  end

  class Scope < Scope
    def resolve
      scope.where(user:)
    end
  end
end
