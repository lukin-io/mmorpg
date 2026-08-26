# frozen_string_literal: true

# Keeps Devise registration and account-update behavior while explicitly
# rejecting account deletion until the product has a retention/anonymization
# policy for immutable gameplay and management records.
class UserRegistrationsController < Devise::RegistrationsController
  DELETION_UNAVAILABLE_MESSAGE = "Account deletion is not available in the current MVP."

  def destroy
    redirect_to edit_user_registration_path,
      alert: DELETION_UNAVAILABLE_MESSAGE,
      status: :see_other
  end
end
