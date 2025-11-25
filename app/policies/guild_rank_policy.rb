# frozen_string_literal: true

class GuildRankPolicy < ApplicationPolicy
  def index?
    guild_member?
  end

  def create?
    leader?
  end

  def update?
    leader?
  end

  def destroy?
    leader?
  end

  class Scope < Scope
    def resolve
      scope.joins(:guild).where(guilds: {id: user.guild_ids})
    end
  end

  private

  def leader?
    record.guild.leader == user
  end

  def guild_member?
    record.guild.guild_memberships.exists?(user:)
  end
end
