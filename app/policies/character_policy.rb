# frozen_string_literal: true

class CharacterPolicy < ApplicationPolicy
  def manage_progression?
    user.present? && record.user_id == user.id
  end
end
