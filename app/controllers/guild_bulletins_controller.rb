# frozen_string_literal: true

class GuildBulletinsController < ApplicationController
  before_action :set_guild, only: [:index, :create]

  def index
    authorize @guild, :show?
    @bulletins = @guild.guild_bulletins.pinned_first
    @guild_bulletin = @guild.guild_bulletins.new
  end

  def create
    membership = current_user.guild_memberships.find_by(guild: @guild)
    Guilds::PermissionService.new(membership:).ensure!(:post_bulletins)

    @guild_bulletin = @guild.guild_bulletins.new(guild_bulletin_params.merge(author: current_user, published_at: Time.current))
    authorize @guild_bulletin

    if @guild_bulletin.save
      redirect_to guild_guild_bulletins_path(@guild), notice: "Bulletin posted."
    else
      @bulletins = @guild.guild_bulletins.pinned_first
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    bulletin = policy_scope(GuildBulletin).find(params[:id])
    authorize bulletin
    bulletin.destroy

    redirect_back fallback_location: guild_guild_bulletins_path(bulletin.guild), notice: "Bulletin removed."
  end

  private

  def set_guild
    @guild = Guild.find(params[:guild_id])
  end

  def guild_bulletin_params
    params.require(:guild_bulletin).permit(:title, :body, :pinned)
  end
end
