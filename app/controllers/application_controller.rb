# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentCharacterContext
  include ArenaEntryGate
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_device_identifier
  before_action :prepare_game_shell_context, if: :user_signed_in?

  layout :resolved_layout

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_device_id

  protected

  def after_sign_in_path_for(resource)
    character = resource.ensure_playable_character! if resource.respond_to?(:ensure_playable_character!)
    return world_path unless character

    Game::World::ResumeContext.new(character:).resume_path
  end

  private

  def resolved_layout
    user_signed_in? ? "game" : "application"
  end

  def prepare_game_shell_context
    character = current_character
    return unless character

    @position ||= character.position
    @players_here ||= if @position
      Character
        .joins(:position)
        .where(character_positions: {
          zone_id: @position.zone_id,
          x: @position.x,
          y: @position.y,
          state: CharacterPosition.states.fetch("active")
        })
        .where.not(id: character.id)
        .order(name: :asc)
        .limit(10)
    else
      []
    end
  end

  def ensure_device_identifier
    current_device_id if user_signed_in?
  end

  def current_device_id
    @current_device_id ||= Auth::DeviceIdentifier.resolve(request)
  end

  def user_not_authorized
    respond_to do |format|
      format.html do
        redirect_target = request.referer.presence

        redirect_target = nil if redirect_target == request.url

        redirect_to(redirect_target || root_path, alert: "You do not have access to this action.")
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: "forbidden"}, status: :forbidden }
    end
  end

  def authorize_world_action_offer!(action_key)
    offer = WorldActionOffer.find_by(action_key: action_key.to_s)
    offer ||= WorldActionOffer.new(character: current_character)
    authorize offer, :accept?
  end
end
