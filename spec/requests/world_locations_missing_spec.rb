# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World locations denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Location Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening an unknown world location key" do
    get world_location_path("__missing_ashen_location__")

    expect(response).to redirect_to(world_path(location_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-location-denied="1"')
    expect(response.body).to include('data-location-recovery="world"')
  end
end
