# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena application denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 0) }
  let(:zone) { create(:zone, name: "Arena App Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:room) { create(:arena_room, level_min: 0, level_max: 10) }

  before do
    sign_in user, scope: :user
    Game::World::ResumeContext.new(character:).remember_arena_entry!
  end

  it "recovers when combat-trauma application lacks a trauma scroll" do
    post arena_room_arena_applications_path(room),
      params: {
        fight_type: "duel",
        fight_kind: "free",
        timeout_seconds: 180,
        combat_trauma: "1"
      }

    expect(response).to redirect_to(arena_index_path(application_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-application-denied="1"')
    expect(response.body).to include('data-application-recovery="lobby"')
  end
end
