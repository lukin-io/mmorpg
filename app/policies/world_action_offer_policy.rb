# frozen_string_literal: true

class WorldActionOfferPolicy < ApplicationPolicy
  def accept?
    user.present? && record.character&.user_id == user.id
  end
end
