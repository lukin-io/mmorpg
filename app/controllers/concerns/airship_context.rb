# frozen_string_literal: true

# Restores the persisted journey before rendering any authenticated game page.
# Ground page reads share the boarding lock. Mutations retain their existing
# transaction/rescue boundaries and recheck travel state under their own locks;
# Arena applications also retain their room-before-character lock order.
module AirshipContext
  extend ActiveSupport::Concern

  GROUND_CONTROLLERS = %w[world world_locations city_buildings shop arena arena_rooms].freeze

  private

  def with_airship_context
    return yield unless user_signed_in? && !devise_controller? && !controller_path.start_with?("manage/") && current_character

    if request.get? && (controller_name.in?(GROUND_CONTROLLERS) || (controller_name == "arena_applications" && action_name == "index"))
      current_character.with_lock { resolve_airship_context { yield } }
    else
      resolve_airship_context { yield }
    end
  end

  def resolve_airship_context
    @active_airship_journey = Game::World::AirshipTravel.new(character: current_character).reconcile!
    @position = current_character.position
    if @active_airship_journey && airship_ground_request?
      respond_to do |format|
        format.json { render json: {error: "Disembark before entering the ground location."}, status: :conflict }
        format.any { redirect_to airship_path, status: :see_other }
      end
    else
      yield
    end
  end

  def airship_ground_request?
    return false if controller_name == "world" && action_name == "players"

    controller_name.in?(GROUND_CONTROLLERS + %w[arena_applications])
  end
end
