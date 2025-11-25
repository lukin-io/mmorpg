# frozen_string_literal: true

class ClanPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  def war?
    declare_war?
  end

  def declare_war?
    gm_or_admin? || permission_matrix.allows?(:declare_war)
  end

  def manage_recruitment?
    gm_or_admin? || permission_matrix.allows?(:manage_recruitment)
  end

  def manage_treasury?
    gm_or_admin? || permission_matrix.allows?(:manage_treasury)
  end

  def manage_infrastructure?
    gm_or_admin? || permission_matrix.allows?(:manage_infrastructure)
  end

  def coordinate_quests?
    gm_or_admin? || permission_matrix.allows?(:coordinate_quests)
  end

  def post_announcements?
    gm_or_admin? || permission_matrix.allows?(:post_announcements)
  end

  def manage_permissions?
    gm_or_admin? || permission_matrix.allows?(:manage_permissions)
  end

  def view_logs?
    gm_or_admin? || leader_membership?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def gm_or_admin?
    user&.has_any_role?(:gm, :admin)
  end

  def leader_membership?
    membership&.leader?
  end

  def membership
    @membership ||= record.clan_memberships.find_by(user: user)
  end

  def permission_matrix
    @permission_matrix ||= Clans::PermissionMatrix.new(clan: record, membership: membership)
  end
end
