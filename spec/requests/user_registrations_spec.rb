# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User registrations", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "DELETE /users" do
    it "rejects cancellation without signing out or reporting a destroyed account" do
      create(:game_event, :fight_finished, recipient: user)

      expect {
        delete user_registration_path
      }.not_to change(User, :count)

      expect(response).to redirect_to(edit_user_registration_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(UserRegistrationsController::DELETION_UNAVAILABLE_MESSAGE)
      expect(User.exists?(user.id)).to be(true)
    end
  end

  describe "GET /users/edit" do
    it "does not offer a cancellation control while deletion is unsupported" do
      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Cancel my account")
    end
  end
end
