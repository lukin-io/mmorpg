require "rails_helper"

RSpec.describe "PublicProfiles", type: :request do
  it "returns a sanitized profile by profile_name" do
    user = create(:user, profile_name: "valor-hero")

    get profile_path(profile_name: user.profile_name)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["profile_name"]).to eq("valor-hero")
    expect(body["id"]).to eq(user.id)
    expect(body).not_to have_key("email")
  end
end
