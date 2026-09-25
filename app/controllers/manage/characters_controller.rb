# frozen_string_literal: true

module Manage
  class CharactersController < ApplicationController
    before_action :load_character, only: [:show, :inject_level, :grant_kit, :toggle_inq]

    def index
      authorize :manage, :access?
      @query = params[:q].to_s.strip
      scope = Character.includes(:user).order(updated_at: :desc)
      if @query.present?
        scope = scope.where("characters.name ILIKE ?", "%#{Character.sanitize_sql_like(@query)}%")
      end
      @characters = scope.limit(50)
    end

    def show
      authorize :manage, :access?
      @combat_rating = @character.metadata.to_h["combat_rating"].to_i
      @inquisitor = Game::Combat::InquisitionImmunity.inquisitor?(@character)
    end

    def inject_level
      authorize :manage, :access?
      result = CharacterTools.new(character: @character).inject_level!(params[:level])
      redirect_to manage_character_path(@character), notice: result.message
    end

    def grant_kit
      authorize :manage, :access?
      result = CharacterTools.new(character: @character).grant_set_kit!(
        set_id: params[:set_id],
        tier: params[:tier]
      )
      flash_key = result.success ? :notice : :alert
      redirect_to manage_character_path(@character), flash_key => result.message
    end

    def toggle_inq
      authorize :manage, :access?
      enabled = !Game::Combat::InquisitionImmunity.inquisitor?(@character)
      result = CharacterTools.new(character: @character).set_inquisition!(enabled:)
      redirect_to manage_character_path(@character), notice: result.message
    end

    private

    def load_character
      @character = Character.find(params[:id])
    end
  end
end
