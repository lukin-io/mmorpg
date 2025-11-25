# frozen_string_literal: true

class ClanMembershipsController < ApplicationController
  def update
    membership = ClanMembership.find(params[:id])
    authorize membership.clan, :manage_permissions?

    if membership.update(role: membership_role_param)
      Clans::LogWriter.new(clan: membership.clan).record!(
        action: "membership.promoted",
        actor: current_user,
        metadata: {membership_id: membership.id, role: membership.role}
      )
      redirect_to clan_path(membership.clan), notice: "Member role updated."
    else
      redirect_to clan_path(membership.clan), alert: "Unable to update role."
    end
  end

  def destroy
    membership = authorize ClanMembership.find(params[:id])
    clan = membership.clan
    membership.destroy
    Clans::LogWriter.new(clan: clan).record!(
      action: "membership.removed",
      actor: current_user,
      metadata: {removed_user_id: membership.user_id}
    )
    redirect_to clan_path(clan), notice: "Removed from clan."
  end

  private

  def membership_role_param
    role = params.require(:clan_membership).fetch(:role).to_s
    return role if ClanMembership.roles.key?(role)

    raise ActionController::BadRequest, "Invalid role"
  end
end
