# frozen_string_literal: true

class ChatChannelPolicy < ApplicationPolicy
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
    record.global? || record.local? || record.system? || record.arena? || record.users.exists?(user.id)
  end
end
