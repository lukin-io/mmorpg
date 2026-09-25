# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World assaults denied recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Assault Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when assaulting a missing defender" do
    post world_assault_path, params: {defender_id: 999_999_999}

    expect(response).to redirect_to(world_path(assault_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-assault-denied="1"')
    expect(response.body).to include('data-assault-recovery="world"')
  end
end
