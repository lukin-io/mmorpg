# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World context action denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Context Deny Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  it "recovers when the shell return context is not allowlisted" do
    post world_context_action_path, params: {context: "https://evil.example"}

    expect(response).to redirect_to(world_path(action_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-action-denied="1"')
    expect(response.body).to include('data-action-recovery="world"')
  end
end
