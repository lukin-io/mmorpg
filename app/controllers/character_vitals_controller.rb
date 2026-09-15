# frozen_string_literal: true

class CharacterVitalsController < ApplicationController
  before_action :ensure_active_character!

  def show
    character = current_character
    character.with_lock do
      Characters::VitalsService.new(character).tick_regeneration
      active = character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).order(:id).last
      response.headers["Cache-Control"] = "no-store"
      render json: {current_hp: active&.defeat? ? 0 : character.current_hp, max_hp: character.effective_max_hp,
                    current_mp: character.current_mp, max_mp: character.effective_max_mp}
    end
  end
end
