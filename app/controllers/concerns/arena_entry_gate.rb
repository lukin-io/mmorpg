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
    return if current_character&.unfinished_arena_result
    if current_character
      context = Game::World::ResumeContext.new(character: current_character)
      return if context.arena_entered? || context.arena_room
      # A persisted application is prior Arena entry evidence, including offers
      # created before room resume was recorded. Recheck the current city/hall.
      application = current_character.waiting_arena_application
      return if application && context.remember_arena_room!(room: application.arena_room)
    end

    respond_to do |format|
      format.html { redirect_to world_path, alert: "Enter the arena through the city building." }
      format.turbo_stream { redirect_to world_path, status: :see_other, alert: "Enter the arena through the city building." }
      format.json do
        render json: {
          success: false,
          error: "arena_city_entry_required",
          errors: ["Enter the arena through the city building."]
        }, status: :forbidden
      end
      format.any { redirect_to world_path, alert: "Enter the arena through the city building." }
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
