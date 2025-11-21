require "rails_helper"

RSpec.describe "SessionPings", type: :request do
  include ActiveJob::TestHelper

  it "enqueues presence job" do
    user = create(:user)
    sign_in user

    expect do
      post session_ping_path, params: { session_ping: { state: "active" } }
    end.to have_enqueued_job(SessionPresenceJob)
  end
end
