# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Closed gameplay sessions", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 20, y: 20) }

  before do
    sign_in user, scope: :user
    get world_path
    @old_cookies = cookies.to_hash
    @move_key = MovementCommand.offered.find_by!(character:, direction: "east").action_key
    delete destroy_user_session_path
  end

  def restore_old_cookies
    @old_cookies.each { |name, value| cookies[name] = value }
  end

  it "rejects stale authenticated HTML after logout instead of rendering the world" do
    restore_old_cookies

    get world_path

    expect(response).to redirect_to(new_user_session_path)
    expect(response.body).not_to include("nl-map-container")
    expect(user.user_sessions.sole.signed_out_at).to be_present
  end

  it "rejects stale map streams and JSON mutations before any gameplay transition" do
    restore_old_cookies
    get world_path, headers: {"Accept" => "text/vnd.turbo-stream.html"}
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).to be_empty

    restore_old_cookies
    expect do
      post move_world_path, params: {action_key: @move_key}, headers: {"Accept" => "application/json"}
    end.not_to change { MovementCommand.moving.count }
    expect(response).to have_http_status(:unauthorized)
    expect(position.reload).to have_attributes(x: 20, y: 20)
  end

  it "allows an explicit new login to reopen the existing device session" do
    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}

    expect(response).to redirect_to(world_path)
    expect(user.user_sessions.sole.signed_out_at).to be_nil
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("nl-map-container")
  end

  it "does not require a new tracking row for an existing legacy authenticated cookie" do
    restore_old_cookies
    user.user_sessions.destroy_all

    get world_path

    expect(response).to have_http_status(:ok)
    expect(user.user_sessions.count).to eq(0)
  end
end
