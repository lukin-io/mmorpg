require "rails_helper"

RSpec.describe "PublicProfiles", type: :request do
  describe "GET /profiles/:profile_name" do
    let(:user) { create(:user, profile_name: "valor-hero") }

    it "returns HTML by default" do
      get profile_path(profile_name: user.profile_name)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/html")
    end

    it "returns a sanitized JSON profile when requested" do
      get profile_path(profile_name: user.profile_name, format: :json)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["profile_name"]).to eq("valor-hero")
      expect(body["id"]).to eq(user.id)
      expect(body).not_to have_key("email")
    end
  end
end
