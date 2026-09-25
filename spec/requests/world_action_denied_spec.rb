# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World local action denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Action Deny Road", location_type: "outdoor") }
  let(:character) { create(:character, user:) }
  let!(:position) { create(:character_position, character:, zone:, x: 3, y: 3) }

  before { sign_in user, scope: :user }

  it "recovers when a local outdoor action target tile is missing" do
    post perform_local_action_world_path, params: {tile_id: 999_999_999, local_action_type: "look"}

    expect(response).to redirect_to(world_path(action_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-action-denied="1"')
    expect(response.body).to include('data-action-recovery="world"')
  end
end
