# frozen_string_literal: true

# Read-only recovery for an incoming scroll attack while viewing a ground page.
# No NPC roll, target or location supplied by the browser can start a fight here.
class CombatStatusesController < ApplicationController
  before_action :ensure_active_character!

  def create
    match = current_character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).first&.arena_match
    match ||= current_character.unfinished_arena_result
    render json: {interrupted: match.present?, redirect_url: match && arena_match_path(match), retry_after_ms: 5000}
  end
end
