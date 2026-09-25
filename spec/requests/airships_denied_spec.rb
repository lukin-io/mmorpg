# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Airships", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Airship Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening the flight map without an active journey" do
    get airship_path, headers: {"Accept" => "text/html"}

    expect(response).to redirect_to(world_path(airship_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-airship-denied="1"')
    expect(response.body).to include('data-airship-recovery="world"')
  end

  it "reports disembarked JSON when no journey is active" do
    get airship_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("phase" => "disembarked")
  end
end
