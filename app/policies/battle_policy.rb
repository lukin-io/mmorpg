# frozen_string_literal: true

class BattlePolicy < ApplicationPolicy
  def show?
    return false unless user

    user.moderator? || participant?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.moderator?
      return scope.none unless user

      scope.joins(:battle_participants).where(battle_participants: {character_id: user.characters.select(:id)})
    end
  end

  private

  def participant?
    record.battle_participants.where(character_id: user.characters.select(:id)).exists?
  end
end
