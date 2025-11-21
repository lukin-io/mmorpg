# frozen_string_literal: true

class GuildApplicationPolicy < ApplicationPolicy
  def update?
    guild_officer? || user&.has_any_role?(:gm, :admin)
  end

  class Scope < Scope
    def resolve
      if user&.has_any_role?(:gm, :admin)
        scope.all
      else
        scope.none
      end
    end
  end

  private

  def guild_officer?
    GuildMembership.where(guild: record.guild, user: user).where(role: %i[officer leader recruiter]).exists?
  end
end

