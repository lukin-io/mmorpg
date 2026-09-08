# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SessionPings", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
    get edit_user_registration_path
  end

  it "refreshes the current user session timestamp" do
    session = user.user_sessions.sole
    session.update!(last_seen_at: 1.minute.ago)

    post session_ping_path

    expect(response).to have_http_status(:no_content)
    expect(user.user_sessions.first.last_seen_at).to be_present
    expect(session.reload.last_seen_at).to be > 30.seconds.ago
  end

  it "does not revive a closed session or update the user from a late heartbeat" do
    session = user.user_sessions.sole
    session.close!
    closed_at = session.signed_out_at
    last_seen_at = user.reload.last_seen_at

    post session_ping_path

    expect(response).to have_http_status(:no_content)
    expect(session.reload).to have_attributes(signed_out_at: closed_at, last_seen_at: closed_at)
    expect(user.reload.last_seen_at).to eq(last_seen_at)
  end

  it "does not recreate a removed session" do
    user.user_sessions.destroy_all

    expect { post session_ping_path }.not_to change(UserSession, :count)
    expect(response).to have_http_status(:no_content)
  end

  it "ignores a submitted foreign user and device" do
    other = create(:user_session, last_seen_at: 1.minute.ago)
    timestamp = other.last_seen_at

    post session_ping_path, params: {user_id: other.user_id, device_id: other.device_id}

    expect(other.reload.last_seen_at).to eq(timestamp)
  end

  it "refreshes an existing open session before rendering the shell online total" do
    session = user.user_sessions.sole
    session.update!(last_seen_at: 10.minutes.ago)
    create(:user_session, last_seen_at: 10.minutes.ago)
    create(:user_session, signed_out_at: Time.current)

    get edit_user_registration_path

    expect(session.reload.last_seen_at).to be > 30.seconds.ago
    expect(Nokogiri::HTML(response.body).at_css(".nl-total-online").text).to eq("Total [ 1 ]")
  end

  it "does not reopen a closed session while preparing shell presence" do
    session = user.user_sessions.sole
    session.close!
    closed_at = session.signed_out_at

    get edit_user_registration_path

    expect(session.reload).to have_attributes(signed_out_at: closed_at, last_seen_at: closed_at)
  end

  it "requires authentication" do
    sign_out user

    expect { post session_ping_path }.not_to change(UserSession, :count)
    expect(response).to redirect_to(new_user_session_path)
  end

  context "with CSRF protection enabled" do
    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    it "rejects an unprotected heartbeat before touching the session" do
      session = user.user_sessions.sole
      original = session.last_seen_at

      post session_ping_path

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session.reload.last_seen_at).to eq(original)
    end

    it "accepts the token included in the authenticated shell" do
      token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]

      post session_ping_path, params: {authenticity_token: token}

      expect(response).to have_http_status(:no_content)
    end
  end
end
