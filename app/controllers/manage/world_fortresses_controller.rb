# frozen_string_literal: true

module Manage
  class WorldFortressesController < ApplicationController
    before_action :set_fortress, only: [:edit, :update]

    def index
      @fortresses = WorldFortress.order(:zone, :y, :x)
      @clans = Clan.order(:name)
    end

    def edit
      @clans = Clan.order(:name)
    end

    def update
      clan = Clan.find_by(id: params.dig(:world_fortress, :owner_clan_id).presence)
      character = if params.dig(:world_fortress, :owner_character_id).present?
        Character.find_by(id: params[:world_fortress][:owner_character_id])
      else
        clan&.leader_character
      end

      if @fortress.update(
        owner_clan: clan,
        owner_character: character,
        name: params.dig(:world_fortress, :name).presence || @fortress.name
      )
        redirect_to manage_world_fortresses_path, notice: I18n.t("manage.flashes.fortress_updated"), status: :see_other
      else
        @clans = Clan.order(:name)
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_fortress
      @fortress = WorldFortress.find(params[:id])
    end
  end
end
