# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World obelisk denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Obelisk Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when the outdoor obelisk action is unknown" do
    post world_obelisk_path, params: {obelisk_action: "__bad__"}

    expect(response).to redirect_to(world_path(obelisk_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-obelisk-denied="1"')
    expect(response.body).to include('data-obelisk-recovery="world"')
  end
end
