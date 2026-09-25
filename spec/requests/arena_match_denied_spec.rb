# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena match denied", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 0, in_combat: true) }
  let(:zone) { create(:zone, name: "Match Deny Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:room) { create(:arena_room, room_type: :help, level_min: 0, level_max: 5) }
  let(:match) { create(:arena_match, :live, arena_room: room) }
  let!(:participation) do
    create(:arena_participation, arena_match: match, character:, user:, team: "a")
  end

  before do
    Game::World::ResumeContext.new(character:).remember_arena_entry!
    sign_in user, scope: :user
  end

  it "recovers when finishing an active fight early" do
    post finish_arena_match_path(match)

    expect(response).to redirect_to(arena_match_path(match, match_denied: 1))
    follow_redirect!
    expect(response.body).to include('data-match-denied="1"')
    expect(response.body).to include('data-match-recovery="lobby"')
  end
end
