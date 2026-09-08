# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentCharacterContext
  include ArenaEntryGate
  include AirshipContext
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_device_identifier
  before_action :reject_closed_game_session
  around_action :with_airship_context
  before_action :prepare_game_shell_context, if: :game_shell_context_request?

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

  # A late concurrent response can restore a pre-logout cookie. The existing
  # device-session closure still revokes gameplay access; absence of a row does
  # not introduce a new authentication prerequisite for legacy sessions.
  def reject_closed_game_session
    return if devise_controller? || controller_name == "session_pings" || !user_signed_in?
    return unless current_user_session&.signed_out_at

    sign_out(current_user)
    respond_to do |format|
      format.html { redirect_to new_user_session_path, status: :see_other }
      format.turbo_stream { head :unauthorized }
      format.json { head :unauthorized }
      format.any { head :unauthorized }
    end
  end

  def resolved_layout
    user_signed_in? ? "game" : "application"
  end

  def game_shell_context_request?
    user_signed_in? &&
      request.get? &&
      request.format.html? &&
      request.headers["Turbo-Frame"].blank?
  end

  def prepare_game_shell_context
    record_current_session_activity
    @global_chat_channel_id ||= ChatChannel.global.pick(:id)
    @total_online ||= UserSession.recent.distinct.count(:user_id)

    character = current_character
    return unless character

    @position ||= character.position
    prepare_presence_context unless controller_name.in?(%w[world world_locations shop city_buildings airships])
  end

  def prepare_presence_context(sort: "az")
    record_current_session_activity
    presence = Game::World::Presence.new(character: current_character, position: @position, sort:).call
    @players_here = presence.players
    @presence_location_label = presence.label
    @presence_player_count = presence.count
    @total_online = UserSession.recent.distinct.count(:user_id)
  end

  def ensure_device_identifier
    current_device_id if user_signed_in?
  end

  def current_device_id
    @current_device_id ||= Auth::DeviceIdentifier.resolve(request)
  end

  def current_user_session
    current_user&.user_sessions&.find_by(device_id: current_device_id)
  end

  def record_current_session_activity
    return if @session_activity_recorded

    @session_activity_recorded = true
    current_user_session&.mark_seen!
  end

  def prepare_local_chat_context
    record_current_session_activity
    @chat_session = current_user_session
    unless @chat_session && @chat_session.signed_out_at.nil?
      raise Pundit::NotAuthorizedError, "Active login required"
    end

    @chat_context = Chat::LocalContext.new(character: current_character).synchronize!
    raise Pundit::NotAuthorizedError, "Current location required" unless @chat_context

    @chat_session_key = "#{current_user.id}:#{@chat_session.id}:#{@chat_session.signed_in_at.iso8601(6)}"
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
