require "rails_helper"

RSpec.describe "Announcements", type: :request do
  describe "POST /announcements" do
    it "responds with a Turbo Stream payload and renders the prepend contract" do
      user = create(:user)
      sign_in user, scope: :user

      expect do
        post announcements_path,
          params: {announcement: {title: "Server Maintenance", body: "We will reboot at midnight UTC."}},
          headers: {"ACCEPT" => Mime[:turbo_stream].to_s}
      end.to change(Announcement, :count).by(1)

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(%(turbo-stream action="prepend" target="announcements_list"))
      expect(response.body).to include("Server Maintenance")
    end
  end
end
