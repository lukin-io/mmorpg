# frozen_string_literal: true

module CurrentCharacterContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_character
  end

  private

  def ensure_active_character!
    @current_character ||= current_user.characters.order(:created_at).first
    raise Pundit::NotAuthorizedError, "Character required" unless @current_character
  end

  def current_character
    @current_character
  end
end
