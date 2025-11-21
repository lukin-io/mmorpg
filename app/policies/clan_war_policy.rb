# frozen_string_literal: true

class ClanWarPolicy < ApplicationPolicy
  def create?
    user&.has_any_role?(:gm, :admin) || user&.clans&.exists?
  end
end
