# frozen_string_literal: true

class ProfessionToolPolicy < ApplicationPolicy
  def repair?
    record.character.user == user
  end
end
