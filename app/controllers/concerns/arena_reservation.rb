# frozen_string_literal: true

# The source locks Character/Inventory/City while waiting. Keep those actions
# behind the same character lock used to reserve a place; a forged request must
# not change equipment or leave after an application has reserved the player.
module ArenaReservation
  extend ActiveSupport::Concern

  RESERVED_CONTROLLERS = %w[world world_locations city_buildings shop inventories inventory_items characters medical_care airships].freeze
  LOBBY_CONTROLLERS = %w[arena arena_rooms arena_applications].freeze

  private

  def recover_arena_applications
    return unless controller_name.in?(RESERVED_CONTROLLERS + LOBBY_CONTROLLERS)
    return unless user_signed_in? && current_character && !devise_controller?

    own = current_character.waiting_arena_application
    scope = if request.get? && controller_name.in?(LOBBY_CONTROLLERS)
      ArenaApplication.where(arena_room_id: ArenaRoom.where(zone_id: [nil, current_character.position&.zone_id]).select(:id))
    else
      ArenaApplication.where(id: own&.id)
    end
    Arena::ApplicationRecovery.call(scope:)
  end

  def with_arena_reservation
    return yield unless user_signed_in? && current_character && controller_name.in?(RESERVED_CONTROLLERS)
    return yield if controller_name == "world" && action_name == "players"

    current_character.with_lock do
      application = current_character.waiting_arena_application
      match = current_character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).where("arena_matches.metadata @> ?", {physical_only: true}.to_json).first&.arena_match
      match ||= current_character.unfinished_arena_result
      if application || match
        destination = match ? arena_match_path(match) : arena_room_path(application.arena_room, ft: application.team_battle? ? 2 : 1)
        respond_to do |format|
          format.json { render json: {success: false, error: "arena_reserved", redirect_url: destination}, status: :conflict }
          format.any { redirect_to destination, status: :see_other, alert: "Finish your fight or withdraw your Arena application first." }
        end
      else
        yield
      end
    end
  end
end
