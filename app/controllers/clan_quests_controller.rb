# frozen_string_literal: true

class ClanQuestsController < ApplicationController
  before_action :set_clan
  before_action :ensure_active_character!, only: :update

  def create
    authorize @clan, :coordinate_quests?
    quest_board.start!(template_key: params[:template_key])
    redirect_to clan_path(@clan), notice: "Clan quest started."
  rescue => e
    redirect_to clan_path(@clan), alert: e.message
  end

  def update
    authorize @clan
    quest = @clan.clan_quests.find(params[:id])
    quest_board.record_contribution!(
      quest: quest,
      character: current_character,
      metric: params[:metric],
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

  def quest_board
    @quest_board ||= Clans::QuestBoard.new(clan: @clan)
  end
end
