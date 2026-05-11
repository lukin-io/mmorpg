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

    it "renders a Neverlands-style character profile by character name" do
      character = create(:character, user: user, name: "Lukin")

      get profile_path(profile_name: character.name)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lukin [#{character.level}]")
      expect(response.body).to include("Primary Stats")
      expect(response.body).not_to include(user.email)
    end

    it "supports the Neverlands pinfo.cgi query-string shape" do
      character = create(:character, user: user, name: "lukin")

      get pinfo_path, env: {"QUERY_STRING" => character.name}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("lukin [#{character.level}]")
    end
  end
end
