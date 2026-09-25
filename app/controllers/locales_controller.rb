# frozen_string_literal: true

class LocalesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :reject_closed_game_session

  def update
    requested = params[:locale].to_s
    available = I18n.available_locales.map(&:to_s)
    denied = available.exclude?(requested)
    locale = denied ? I18n.default_locale.to_s : requested

    session[:locale] = locale
    cookies.permanent[:locale] = locale

    if denied
      fallback = user_signed_in? ? world_path(locale_denied: 1) : root_path(locale_denied: 1)
      redirect_to fallback, status: :see_other
    else
      redirect_back fallback_location: root_path, status: :see_other
    end
  end
end
