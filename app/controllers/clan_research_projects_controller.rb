# frozen_string_literal: true

class ClanResearchProjectsController < ApplicationController
  before_action :set_clan

  def create
    authorize @clan, :manage_infrastructure?
    research_service.queue!(track: params[:track], tier: params[:tier])
    redirect_to clan_path(@clan), notice: "Research project queued."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  def update
    authorize @clan, :manage_infrastructure?
    project = @clan.clan_research_projects.find(params[:id])
    research_service.contribute!(
      project: project,
      resource_key: params[:resource_key],
      amount: params[:amount].to_i
    )
    redirect_to clan_path(@clan), notice: "Research contribution recorded."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  private

  def set_clan
    @clan = Clan.find(params[:clan_id])
  end

  def research_service
    @research_service ||= Clans::ResearchService.new(clan: @clan, membership: membership)
  end

  def membership
    @membership ||= @clan.clan_memberships.find_by(user: current_user)
  end
end
