# frozen_string_literal: true

class ChatChannelPolicy < ApplicationPolicy
  def index?
    user&.verified_for_social_features?
  end

  def show?
    user&.verified_for_social_features? && accessible?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.verified_for_social_features?

      public_scope = scope.public_channels
      membership_scope = scope.where(id: user.chat_channel_ids)
      public_scope.or(membership_scope)
    end
  end

  private

  def accessible?
    record.global? || record.local? || record.users.exists?(user.id)
  end
end
