# frozen_string_literal: true

module Moderation
  class TicketPolicy < ApplicationPolicy
    def index?
      moderator?
    end

    def show?
      moderator? || record.reporter == user
    end

    def create?
      user&.verified_for_social_features?
    end

    def update?
      moderator?
    end

    def appeal?
      record.reporter == user
    end

    class Scope < Scope
      def resolve
        return scope.all if moderator?
        return scope.none unless user

        scope.where(reporter: user)
      end

      private

      def moderator?
        user&.moderator?
      end
    end

    private

    def moderator?
      user&.moderator?
    end
  end
end
