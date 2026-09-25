# frozen_string_literal: true

require "rails_helper"

RSpec.describe "City buildings missing key recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Building Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when opening an unknown building key" do
    get city_building_path("__missing_ashen_building__")

    expect(response).to redirect_to(world_path(building_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-building-denied="1"')
    expect(response.body).to match(/data-building-recovery="(?:main|world)"/)
  end
end
