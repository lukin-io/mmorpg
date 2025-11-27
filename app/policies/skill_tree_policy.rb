# frozen_string_literal: true

# Policy for skill tree access and unlock permissions.
class SkillTreePolicy < ApplicationPolicy
  def index?
    user_with_character?
  end

  def show?
    user_with_character? && record.character_class_id == user.character&.character_class_id
  end

  def unlock?
    user_with_character? && record.character_class_id == user.character&.character_class_id
  end

  def respec?
    user_with_character?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def user_with_character?
    user.present? && user.character.present?
  end
end
