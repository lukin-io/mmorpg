# frozen_string_literal: true

class ClansController < ApplicationController
  def index
    @clans = policy_scope(Clan).includes(:leader).order(prestige: :desc)
  end

  def show
    @clan = authorize Clan.find(params[:id])
    @territories = @clan.clan_territories
    @wars = ClanWar.where(attacker_clan: @clan).or(ClanWar.where(defender_clan: @clan))
  end

  def new
    @clan = authorize Clan.new
  end

  def create
    @clan = authorize Clan.new(clan_params.merge(leader: current_user))
    if @clan.save
      @clan.clan_memberships.create!(user: current_user, role: :leader, joined_at: Time.current)
      redirect_to @clan, notice: "Clan founded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def clan_params
    params.require(:clan).permit(:name, :description)
  end
end

