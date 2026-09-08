# frozen_string_literal: true

class ChatChannelPolicy < ApplicationPolicy
  def show?
    user&.verified_for_social_features? && accessible?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.verified_for_social_features?

      public_scope = scope.where(channel_type: [:global, :system])
      membership_scope = scope.where(channel_type: [:whisper, :arena], id: user.chat_channel_ids)
      local_key = Chat::LocalContext.new(character: user.character).key
      local_scope = local_key.present? ? scope.local.where("metadata ->> 'location_key' = ?", local_key) : scope.none
      public_scope.or(membership_scope).or(local_scope)
    end
  end

  private

  def accessible?
    return true if record.global? || record.system?
    if record.local?
      key = Chat::LocalContext.new(character: user.character).key
      return key.present? && record.metadata.to_h["location_key"] == key
    end

    record.users.exists?(user.id)
  end
end
