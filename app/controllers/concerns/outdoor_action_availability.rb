# frozen_string_literal: true

# Keeps player-issued navigation and inventory/progression changes behind the
# persisted outdoor travel/Look state. The character lock remains held through
# the request so a concurrent move cannot start after the availability check.
# City pages and existing combat access rules are unchanged.
module OutdoorActionAvailability
  extend ActiveSupport::Concern

  private

  def with_available_outdoor_actions
    current_character.with_lock do
      if current_character.position&.zone&.outdoor?
        previous_cell = current_character.position.attributes.slice("zone_id", "x", "y")
        Game::Movement::CompleteMove.new(character: current_character).call
        active_action = Game::World::LocalActionState.new(character: current_character).call
        @position = current_character.position

        message = if MovementCommand.moving.where(character: current_character).exists?
          "Movement already in progress."
        elsif active_action
          "A local action is already in progress."
        end
        if message
          redirect_to world_path, alert: message, status: :see_other
          next
        end

        if previous_cell != @position&.attributes&.slice("zone_id", "x", "y") && game_shell_context_request?
          prepare_presence_context
        end
      end

      yield
    end
  end
end
