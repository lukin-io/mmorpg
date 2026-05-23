require "rails_helper"

RSpec.describe "SessionPings", type: :request do
  it "refreshes the current user session timestamp" do
    user = create(:user)
    sign_in user, scope: :user

    post session_ping_path

    expect(response).to have_http_status(:no_content)
    expect(user.user_sessions.first.last_seen_at).to be_present
  end
end
