# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World hotspot denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:city) { create(:zone, :city_node, name: "Hotspot Deny City") }
  let(:character) { create(:character, user:, level: 10) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when interacting with a missing city hotspot" do
    post interact_hotspot_world_path, params: {hotspot_id: 999_999_999}

    expect(response).to redirect_to(world_path(hotspot_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-hotspot-denied="1"')
    expect(response.body).to include('data-hotspot-recovery="world"')
  end
end
