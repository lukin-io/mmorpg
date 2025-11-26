# frozen_string_literal: true

require "rails_helper"
require "cgi"

RSpec.describe "GameOverview", type: :request do
  describe "GET /game_overview" do
    it "renders successfully for anonymous visitors" do
      get game_overview_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Elselands Game Overview")
      expect(CGI.unescapeHTML(response.body)).to include("Vision & Objectives")
    end

    it "streams metrics for Turbo requests" do
      get game_overview_path(format: :turbo_stream)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
