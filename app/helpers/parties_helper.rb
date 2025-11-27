# frozen_string_literal: true

# Helpers for party views.
module PartiesHelper
  def current_user_party
    @current_user_party ||= current_user.parties
      .joins(:party_memberships)
      .where(party_memberships: {user_id: current_user.id, status: :active})
      .first
  end

  def party_member?(party)
    party.party_memberships.exists?(user: current_user, status: :active)
  end

  def party_leader?(party)
    party.leader == current_user
  end

  def current_membership
    @current_membership ||= @party.party_memberships.find_by(user: current_user)
  end

  def can_join_party?(party)
    return false if party_member?(party)
    return false if party.active_members.count >= party.max_size
    return false if party.party_invitations.exists?(user: current_user, status: :pending)

    true
  end
end
