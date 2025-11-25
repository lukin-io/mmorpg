# frozen_string_literal: true

class GuildRanksController < ApplicationController
  before_action :set_guild, only: [:index, :create]
  before_action :set_rank, only: [:update, :destroy]

  def index
    authorize @guild, :show?
    @ranks = @guild.guild_ranks.ordered
    @guild_rank = @guild.guild_ranks.new
  end

  def create
    authorize_leader!
    @guild_rank = @guild.guild_ranks.new(guild_rank_params)

    if @guild_rank.save
      redirect_to guild_guild_ranks_path(@guild), notice: "Rank created."
    else
      @ranks = @guild.guild_ranks.ordered
      render :index, status: :unprocessable_entity
    end
  end

  def update
    authorize_leader!
    if @guild_rank.update(guild_rank_params)
      redirect_back fallback_location: guild_guild_ranks_path(@guild_rank.guild), notice: "Rank updated."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_leader!
    guild = @guild_rank.guild
    @guild_rank.destroy
    redirect_to guild_guild_ranks_path(guild), notice: "Rank removed."
  end

  private

  def set_guild
    @guild = Guild.find(params[:guild_id])
  end

  def set_rank
    @guild_rank = GuildRank.find(params[:id])
  end

  def authorize_leader!
    guild = @guild || @guild_rank&.guild
    raise Pundit::NotAuthorizedError unless guild&.leader == current_user
  end

  def guild_rank_params
    params.require(:guild_rank).permit(:name, :position, permissions: {})
  end
end
