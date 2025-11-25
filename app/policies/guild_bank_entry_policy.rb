# frozen_string_literal: true

class GuildBankEntryPolicy < ApplicationPolicy
  def index?
    guild_member?
  end

  def create?
    guild_member?
  end

  private

  def guild_member?
    return false unless user

    GuildMembership.exists?(guild: record.guild, user: user)
  end
end
