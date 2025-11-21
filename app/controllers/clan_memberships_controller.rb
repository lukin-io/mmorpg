# frozen_string_literal: true

class ClanMembershipsController < ApplicationController
  def destroy
    membership = authorize ClanMembership.find(params[:id])
    membership.destroy
    redirect_to clan_path(membership.clan), notice: "Removed from clan."
  end
end
