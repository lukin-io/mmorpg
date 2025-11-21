# frozen_string_literal: true

class GuildMembershipsController < ApplicationController
  def destroy
    membership = authorize GuildMembership.find(params[:id])
    membership.destroy
    redirect_to guild_path(membership.guild), notice: "Member removed."
  end

  def update
    membership = authorize GuildMembership.find(params[:id])
    membership.update!(membership_params)
    redirect_to guild_path(membership.guild), notice: "Membership updated."
  end

  private

  def membership_params
    params.require(:guild_membership).permit(:role, :status)
  end
end
