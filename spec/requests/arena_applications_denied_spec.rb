# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena applications denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:zone) { create(:zone, name: "Arena App Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before do
    Game::World::ResumeContext.new(character:).remember_arena_entry!
    sign_in user, scope: :user
  end

  it "recovers when accepting a missing arena application" do
    post accept_arena_application_path(999_999_999)

    expect(response).to redirect_to(arena_index_path(arena_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-arena-denied="1"')
    expect(response.body).to include('data-arena-recovery="city"').or include('data-arena-recovery="duels"')
  end

  it "recovers when creating an application in a missing arena room" do
    post arena_room_arena_applications_path(999_999_999), params: {fight_type: 1}

    expect(response).to redirect_to(arena_index_path(arena_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-arena-denied="1"')
    expect(response.body).to include('data-arena-recovery="city"').or include('data-arena-recovery="duels"')
  end
end
