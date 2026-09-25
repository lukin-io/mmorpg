# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena Help Hall", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 0) }
  let(:zone) { create(:zone, name: "Help Hall Spec City", location_type: "city") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let!(:help_hall) { create(:arena_room, room_type: :help, name: "Help Hall", slug: "help-spec", level_min: 0, level_max: 5) }

  before do
    Game::World::ResumeContext.new(character:).remember_arena_entry!
    sign_in user, scope: :user
  end

  it "lets a level-zero character open the Help Hall room" do
    get arena_room_path(help_hall)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("nl-arena-frame")
  end

  it "ensures a training dummy application on Help Hall" do
    expect {
      get arena_room_path(help_hall)
    }.to change { ArenaApplication.open.from_npcs.where(arena_room: help_hall).count }.by(1)

    expect(response).to have_http_status(:success)
    expect(response.body).to include("nl-arena-row--npc").or include("Пепельный манекен").or include("accept")
  end
end
