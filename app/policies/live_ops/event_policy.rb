# frozen_string_literal: true

module LiveOps
  class EventPolicy < ApplicationPolicy
    def index?
      moderator?
    end

    def create?
      gm_or_admin?
    end

    def update?
      gm_or_admin?
    end

    class Scope < Scope
      def resolve
        return scope.all if user&.moderator?

        scope.none
      end
    end

    private

    def moderator?
      user&.moderator?
    end

    def gm_or_admin?
      user&.has_any_role?(:gm, :admin)
    end
  end
end
