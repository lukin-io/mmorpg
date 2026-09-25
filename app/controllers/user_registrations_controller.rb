# frozen_string_literal: true

# Keeps Devise registration and account-update behavior while explicitly
# rejecting account deletion until the product has a retention/anonymization
# policy for immutable gameplay and management records.
class UserRegistrationsController < Devise::RegistrationsController
  DELETION_UNAVAILABLE_MESSAGE = -> { I18n.t("game.flashes.account_deletion_unavailable") }

  before_action :configure_sign_up_params, only: [:create]

  def destroy
    redirect_to edit_user_registration_path,
      alert: DELETION_UNAVAILABLE_MESSAGE.call,
      status: :see_other
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:profile_name])
  end

  def after_sign_up_path_for(resource)
    character = resource.ensure_playable_character! if resource.respond_to?(:ensure_playable_character!)
    return world_path unless character

    Game::World::ResumeContext.new(character:).resume_path
  end
end
