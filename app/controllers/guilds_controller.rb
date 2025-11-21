# frozen_string_literal: true

class GuildsController < ApplicationController
  def index
    @guilds = policy_scope(Guild).includes(:leader).order(level: :desc)
  end

  def show
    @guild = authorize Guild.find(params[:id])
    @memberships = @guild.guild_memberships.includes(:user)
    @applications = policy_scope(GuildApplication).where(guild: @guild).pending if current_user.has_role?(:gm)
  end

  def new
    @guild = authorize Guild.new
  end

  def create
    @guild = authorize Guild.new(guild_params.merge(leader: current_user))
    if @guild.save
      @guild.guild_memberships.create!(user: current_user, role: :leader, status: :active, joined_at: Time.current)
      redirect_to @guild, notice: "Guild founded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def guild_params
    params.require(:guild).permit(:name, :motto)
  end
end
