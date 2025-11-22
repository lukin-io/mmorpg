# frozen_string_literal: true

class GuildMembershipPolicy < ApplicationPolicy
  def update?
    moderator_or_leader?
  end

  def destroy?
    moderator_or_leader? || record.user == user
  end

  def permitted_attributes
    attrs = [:status]
    attrs << :role if moderator_or_leader?
    attrs
  end

  class Scope < Scope
    def resolve
      scope.joins(:guild).where(guilds: {id: user.guild_ids})
    end
  end

  private

  def moderator_or_leader?
    record.guild.leader == user || user&.has_any_role?(:gm, :admin)
  end
end
