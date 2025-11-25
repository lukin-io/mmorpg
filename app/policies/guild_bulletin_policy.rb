# frozen_string_literal: true

class GuildBulletinPolicy < ApplicationPolicy
  def create?
    guild_member?
  end

  def destroy?
    record.author == user || record.guild.leader == user
  end

  class Scope < Scope
    def resolve
      scope.joins(guild: :guild_memberships).where(guild_memberships: {user_id: user.id})
    end
  end

  private

  def guild_member?
    return false unless user

    record.guild.guild_memberships.exists?(user:)
  end
end
