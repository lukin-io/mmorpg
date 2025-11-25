# frozen_string_literal: true

class ClanStrongholdUpgradesController < ApplicationController
  before_action :set_clan

  def create
    authorize @clan, :manage_infrastructure?
    service.queue!(upgrade_key: params[:upgrade_key])
    redirect_to clan_path(@clan), notice: "Upgrade queued."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  def update
    authorize @clan, :manage_infrastructure?
    upgrade = @clan.clan_stronghold_upgrades.find(params[:id])
    service.contribute!(
      upgrade: upgrade,
      item_key: params[:item_key],
      amount: params[:amount].to_i
    )
    redirect_to clan_path(@clan), notice: "Contribution recorded."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def service
    @service ||= Clans::StrongholdService.new(clan: @clan, membership: membership)
  end

  def membership
    @membership ||= @clan.clan_memberships.find_by(user: current_user)
  end
end
