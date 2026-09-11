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

  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def rendered_authenticity_token
    Nokogiri::HTML(response.body).at_css('form input[name="authenticity_token"]')["value"]
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

  it "does not redirect background HTML or frame reads into a second sign-in form" do
    [{"X-Requested-With" => "XMLHttpRequest"}, {"Turbo-Frame" => "chat_messages"}].each do |headers|
      restore_old_cookies

      get local_chat_path(poll: 1), headers: headers.merge("Accept" => "text/html")

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Location"]).to be_nil
      expect(response.body).to be_empty
      expect(user.user_sessions.sole.signed_out_at).to be_present
    end
  end

  it "allows an explicit new login to reopen the existing device session" do
    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}

    expect(response).to redirect_to(world_path)
    expect(user.user_sessions.sole.signed_out_at).to be_nil
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("nl-map-container")
  end

  it "renders sign-in for a restored closed-session cookie without reopening it" do
    restore_old_cookies

    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="user_password"')
    expect(response.body).not_to include("You are already signed in")
    expect(user.user_sessions.sole.signed_out_at).to be_present
  end

  it "authenticates the first password submission despite a restored closed-session cookie" do
    restore_old_cookies

    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}

    expect(response).to redirect_to(world_path)
    expect(user.user_sessions.sole.signed_out_at).to be_nil
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("nl-map-container")
    expect(response.body).not_to include("You are already signed in")
  end

  it "still requires correct credentials when the authenticated cookie belongs to a closed session" do
    restore_old_cookies

    post user_session_path, params: {user: {email: user.email, password: "incorrect"}}

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('id="user_password"')
    expect(user.user_sessions.sole.signed_out_at).to be_present
    get world_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "preserves Devise's already-authenticated behavior for an open login" do
    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}
    signed_in_at = user.user_sessions.sole.signed_in_at

    get new_user_session_path

    expect(response).to redirect_to(world_path)
    expect(user.user_sessions.sole).to have_attributes(signed_in_at:, signed_out_at: nil)
  end

  it "accepts a matching CSRF token while discarding a closed authenticated login" do
    with_forgery_protection do
      get new_user_session_path
      post user_session_path, params: {authenticity_token: rendered_authenticity_token,
                                     user: {email: user.email, password: "Password123!"}}
      expect(response).to redirect_to(world_path)
      get world_path
      token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]
      user.user_sessions.sole.close!

      post user_session_path, params: {authenticity_token: token,
                                     user: {email: user.email, password: "Password123!"}}

      expect(response).to redirect_to(world_path)
      expect(user.user_sessions.sole.signed_out_at).to be_nil
    end
  end

  it "rejects a stale sign-in CSRF token with a fresh form and requires explicit resubmission" do
    with_forgery_protection do
      get new_user_session_path
      token = rendered_authenticity_token
      # A response started before logout can overwrite the form's newer cookie.
      restore_old_cookies

      post user_session_path, params: {authenticity_token: token,
                                     user: {email: user.email, password: "Password123!"}}

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(new_user_session_path)
      expect(user.user_sessions.sole.signed_out_at).to be_present
      follow_redirect!
      expect(response.body).to include("Your sign-in form expired. Please enter your details again.")
      expect(response.body).not_to include("Password123!")
      post user_session_path, params: {authenticity_token: rendered_authenticity_token,
                                     user: {email: user.email, password: "Password123!"}}

      expect(response).to redirect_to(world_path)
      expect(user.user_sessions.sole.signed_out_at).to be_nil
    end
  end

  it "does not require a new tracking row for an existing legacy authenticated cookie" do
    restore_old_cookies
    user.user_sessions.destroy_all

    get world_path

    expect(response).to have_http_status(:ok)
    expect(user.user_sessions.count).to eq(0)
  end
end
