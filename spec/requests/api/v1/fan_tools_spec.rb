require "rails_helper"

RSpec.describe "Api::V1::FanTools", type: :request do
  describe "GET /api/v1/fan_tools" do
    it "returns achievements and housing showcase when token valid" do
      token = create(:integration_token)
      create(:achievement, name: "Explorer", category: "exploration")
      create(:housing_plot, :showcased, user: create(:user, profile_name: "Tester"))

      get api_v1_fan_tools_path, params: {token: token.token}

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["achievements"]).not_to be_empty
      expect(json["housing_showcase"]).not_to be_empty
    end

    it "returns unauthorized without token" do
      get api_v1_fan_tools_path
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
