# frozen_string_literal: true

module ArenaEntryGate
  extend ActiveSupport::Concern

  private

  # Room/lobby HTML entry changes persisted location. Keep its availability
  # check and rendering in the same character boundary as movement and fights.
  # No room lock is acquired: application creation already locks room first.
  def with_city_arena_entry
    current_character.with_lock do
      require_city_arena_entry!
      unless performed?
        @position = current_character.position
        yield
      end
    end
  end

  def require_city_arena_entry!
    return if current_character_has_active_arena_match?
    if current_character
      context = Game::World::ResumeContext.new(character: current_character)
      return if context.arena_entered? || context.arena_room
    end

    respond_to do |format|
      format.html { redirect_to world_path(arena_gate_denied: 1), alert: I18n.t("game.flashes.arena_gate") }
      format.turbo_stream { redirect_to world_path(arena_gate_denied: 1), status: :see_other, alert: I18n.t("game.flashes.arena_gate") }
      format.json do
        render json: {
          success: false,
          error: "arena_city_entry_required",
          errors: [I18n.t("game.flashes.arena_gate")]
        }, status: :forbidden
      end
      format.any { redirect_to world_path(arena_gate_denied: 1), alert: I18n.t("game.flashes.arena_gate") }
    end
  end

  def current_character_has_active_arena_match?
    return false unless current_character

    current_character.arena_participations
      .joins(:arena_match)
      .where(arena_matches: {status: [:pending, :matching, :live]})
      .exists?
  end
end
