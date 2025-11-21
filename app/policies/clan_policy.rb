# frozen_string_literal: true

class ClanPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  def war?
    leader_or_gm?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def leader_or_gm?
    record.leader == user || user&.has_any_role?(:gm, :admin)
  end
end
