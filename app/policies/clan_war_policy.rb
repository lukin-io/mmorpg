# frozen_string_literal: true

class ClanWarPolicy < ApplicationPolicy
  def create?
    return true if user&.has_any_role?(:gm, :admin)

    clan = extract_clan(record)
    return false unless clan

    membership = clan.clan_memberships.find_by(user: user)
    return false unless membership

    Clans::PermissionMatrix.new(clan:, membership: membership).allows?(:declare_war)
  end

  private

  def extract_clan(record)
    case record
    when ClanWar
      record.attacker_clan
    when Clan
      record
    else
      nil
    end
  end
end
