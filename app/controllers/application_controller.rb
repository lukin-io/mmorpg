# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentCharacterContext
  include ArenaEntryGate
  include AirshipContext
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :ensure_device_identifier
  before_action :reject_closed_game_session
  around_action :switch_locale
  around_action :with_airship_context
  before_action :prepare_game_shell_context, if: :game_shell_context_request?

  layout :resolved_layout

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # Soft-launch crash net: one global handler — do NOT wrap each action in begin/rescue
  # (duplicates this net, hides bugs in test/dev, and can swallow mid-transaction errors).
  rescue_from ActiveRecord::RecordNotFound, with: :soft_launch_safety_net
  rescue_from StandardError, with: :soft_launch_safety_net

  helper_method :current_device_id

  protected

  def soft_launch_safety_net(error)
    raise error if Rails.env.local? || Rails.env.test?
    raise error if manage_namespace?
    raise error if passthrough_error?(error)

    Rails.logger.error(
      "[soft_launch_safety] #{error.class}: #{error.message}\n" \
      "#{Array(error.backtrace).first(15).join("\n")}"
    )
    begin
      Rails.error.report(error)
    rescue StandardError
      nil
    end

    alert = I18n.t("errors.temporary_glitch")
    # Never redirect world→world: a raise in WorldController#show would loop.
    # Player routes have no characters#index — inventory is a safe alternate shell.
    recovery_path =
      if request.path.to_s.start_with?("/world")
        inventory_path
      else
        world_path
      end

    respond_to do |format|
      format.html do
        redirect_to(recovery_path, alert:, status: :see_other)
      end
      format.turbo_stream do
        flash[:alert] = alert
        redirect_to recovery_path, status: :see_other
      end
      format.json { render json: {error: alert}, status: :unprocessable_entity }
      format.any { head :unprocessable_entity }
    end
  end

  def passthrough_error?(error)
    # RecordNotFound is soft-handled above in production soft-launch.
    error.is_a?(ActionController::RoutingError) ||
      error.is_a?(AbstractController::ActionNotFound) ||
      error.is_a?(ActionController::UnknownFormat) ||
      error.is_a?(ActionController::InvalidAuthenticityToken) ||
      error.is_a?(ActionController::BadRequest) ||
      error.is_a?(ActionController::ParameterMissing) ||
      error.is_a?(Pundit::NotAuthorizedError)
  end

  def manage_namespace?
    controller_path.to_s.start_with?("manage/")
  end

  def switch_locale(&action)
    locale = params[:locale].presence || session[:locale].presence || cookies[:locale].presence || I18n.default_locale
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
    session[:locale] = locale.to_s
    I18n.with_locale(locale, &action)
  end

  def after_sign_in_path_for(resource)
    stored = stored_location_for(resource)
    return stored if stored.to_s.start_with?("/manage")

    character = resource.ensure_playable_character! if resource.respond_to?(:ensure_playable_character!)
    return world_path unless character

    if (unresolved = Game::World::UnresolvedFight.new(character:).match)
      return arena_match_path(unresolved)
    end

    path = Game::World::ResumeContext.new(character:).resume_path
    # Stale shop filter URLs (min_level>max etc.) 404 after login — fall back to World.
    return world_path if path.to_s.start_with?("/shop?") && path.include?("min_level=")

    path
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
      format.html do
        if request.xhr? || request.headers["Turbo-Frame"].present?
          head :unauthorized
        else
          redirect_to new_user_session_path, status: :see_other
        end
      end
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

    Characters::VitalsService.new(character).catch_up_regeneration!
    character.reload
    @position ||= character.position
    prepare_presence_context unless controller_name.in?(%w[world world_locations shop city_buildings airships])
    @first_hour = Game::Onboarding::FirstHour.new(character:)
    @first_hour.ensure_bootstrapped!
    @activity_claimable = Game::Activity::Tracker.new(character:).claimable_contract_count
    prepare_mist_shell_fomo!(character)
  end

  def prepare_mist_shell_fomo!(character)
    # Board-only Pulse: warm sieges without spawning ambushes/city raids on every page.
    Game::WorldEvents::Pulse.new.call(scope: :board)
    @wars_siege_count = Game::World::SectorWarBoard.new.call.count(&:under_siege)
    return unless Game::Seasons::Catalog.active?

    snap = Game::Seasons::Progress.new(character:).snapshot
    @season_days_left = [snap[:days_left].to_i, Game::Seasons::Catalog.days_remaining].max
    @season_claimable = Array(snap[:free_levels]).size
    @season_claimable += Array(snap[:premium_levels]).size if snap[:premium]
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
      raise Pundit::NotAuthorizedError, I18n.t("game.chat.login_required")
    end

    @chat_context = Chat::LocalContext.new(character: current_character).synchronize!
    raise Pundit::NotAuthorizedError, I18n.t("game.chat.location_required") unless @chat_context

    @chat_session_key = "#{current_user.id}:#{@chat_session.id}:#{@chat_session.signed_in_at.iso8601(6)}"
  end

  def user_not_authorized(exception = nil)
    alert = exception&.message.to_s.strip
    alert = I18n.t("errors.forbidden") if alert.blank? ||
      alert == "Pundit::NotAuthorizedError" ||
      alert.start_with?("not allowed to")

    respond_to do |format|
      format.html do
        redirect_target = request.referer.presence

        redirect_target = nil if redirect_target == request.url

        redirect_to(redirect_target || root_path, alert:)
      end
      format.turbo_stream { head :forbidden }
      format.json { render json: {error: alert}, status: :forbidden }
    end
  end

  def authorize_world_action_offer!(action_key)
    offer = WorldActionOffer.find_by(action_key: action_key.to_s)
    offer ||= WorldActionOffer.new(character: current_character)
    authorize offer, :accept?
  end
end
