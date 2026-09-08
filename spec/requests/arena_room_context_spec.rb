# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena room location context", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:city) { create(:zone, :city) }
  let!(:position) { create(:character_position, character:, zone: city, x: 5, y: 5) }
  let!(:hotspot) { create(:city_hotspot, :arena, zone: city) }
  let(:room) { create(:arena_room, zone: city, name: "First Hall") }
  let(:other_room) { create(:arena_room, zone: city, name: "Second Hall") }

  before { sign_in user, scope: :user }

  def enter_arena
    offer = create(:world_action_offer, character:, zone: city, x: position.x, y: position.y,
      action_type: "enter_city_building", target: hotspot)
    post interact_hotspot_world_path, params: {hotspot_id: hotspot.id, action_key: offer.action_key}
  end

  it "persists the visited room and keeps it on room reload and lobby navigation" do
    enter_arena
    get arena_room_path(room)
    expect(response).to have_http_status(:ok)
    expect(character.reload.gameplay_context).to eq("name" => "arena_room", "params" => {"room_id" => room.id})

    get arena_room_path(other_room)
    expect(response).to have_http_status(:ok)
    expect(character.reload.gameplay_context.dig("params", "room_id")).to eq(other_room.id)
    saved = character.metadata.fetch("local_chat_context")

    get arena_room_path(other_room)
    get arena_index_path
    expect(response).to have_http_status(:ok)
    expect(character.reload.gameplay_context.dig("params", "room_id")).to eq(other_room.id)
    expect(character.metadata.fetch("local_chat_context")).to eq(saved)
    expect(position.reload).to have_attributes(zone: city, x: 5, y: 5)
  end

  it "does not turn a JSON preview of another room into a location change" do
    enter_arena
    get arena_room_path(room)
    saved = character.reload.metadata.slice("gameplay_context", "local_chat_context")

    get arena_room_path(other_room), as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("room", "id")).to eq(other_room.id)
    expect(character.reload.metadata.slice("gameplay_context", "local_chat_context")).to eq(saved)
  end

  it "uses the same playable character as city entry, presence, and chat when creation order differs from ids" do
    playable = create(:character, user:, level: 10, created_at: 1.day.ago)
    create(:character_position, character: playable, zone: city, x: 5, y: 5)
    offer = create(:world_action_offer, character: playable, zone: city, x: 5, y: 5,
      action_type: "enter_city_building", target: hotspot)
    post interact_hotspot_world_path, params: {hotspot_id: hotspot.id, action_key: offer.action_key}

    get arena_index_path
    expect(response).to have_http_status(:ok)
    get arena_room_path(room)
    expect(response).to have_http_status(:ok)
    expect(playable.reload.gameplay_context.dig("params", "room_id")).to eq(room.id)
    expect(character.reload.gameplay_context["name"]).to eq("world")

    post arena_room_arena_applications_path(room),
      params: {arena_application: {fight_type: "duel"}}, as: :json
    expect(response).to have_http_status(:created)
    expect(ArenaApplication.last.applicant).to eq(playable)
    expect(character.arena_applications).to be_empty
  end

  it "does not select an invented default room on the initial lobby visit" do
    enter_arena
    get arena_index_path

    expect(response).to have_http_status(:ok)
    expect(character.reload.gameplay_context).to eq("name" => "world", "params" => {})
  end

  it "limits lobby rooms to the current city and existing global rooms" do
    room
    global_room = create(:arena_room)
    foreign_room = create(:arena_room, zone: create(:zone, :city))
    enter_arena

    get arena_index_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("rooms").pluck("id")).to contain_exactly(room.id, global_room.id)
    expect(response.parsed_body.fetch("rooms").pluck("id")).not_to include(foreign_room.id)
  end

  it "rejects an inaccessible or foreign-city room without changing the current room" do
    enter_arena
    get arena_room_path(room)
    other_room.update!(level_min: character.level + 1)
    get arena_room_path(other_room)
    expect(response).to redirect_to(arena_index_path)

    other_room.update!(level_min: 1, zone: create(:zone, :city))
    get arena_room_path(other_room)
    expect(response).to redirect_to(arena_index_path)
    expect(character.reload.gameplay_context.dig("params", "room_id")).to eq(room.id)
  end

  it "rejects foreign-city application list, create, and acceptance URLs" do
    enter_arena
    foreign_city = create(:zone, :city)
    foreign_room = create(:arena_room, zone: foreign_city)
    applicant = create(:character, level: 10)
    create(:character_position, character: applicant, zone: foreign_city)
    application = create(:arena_application, arena_room: foreign_room, applicant:)

    get arena_room_arena_applications_path(foreign_room), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.body).not_to include(applicant.name)

    expect do
      post arena_room_arena_applications_path(foreign_room), params: {arena_application: {fight_type: "duel"}}, as: :json
    end.not_to change(ArenaApplication, :count)
    expect(response).to have_http_status(:unprocessable_content)

    expect do
      post accept_arena_application_path(application), as: :json
    end.not_to change(ArenaMatch, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(application.reload).to be_open
  end

  it "rechecks current city access instead of trusting an old entry cookie" do
    enter_arena
    hotspot.update!(active: false)
    get arena_room_path(room)
    expect(response).to redirect_to(world_path)

    hotspot.update!(active: true)
    other_city = create(:zone, :city)
    create(:city_hotspot, :arena, zone: other_city)
    position.update!(zone: other_city)
    get arena_index_path
    expect(response).to redirect_to(world_path)
    expect(character.reload.gameplay_context["name"]).to eq("world")
  end

  it "redirects to an existing fight without replacing the selected room" do
    enter_arena
    get arena_room_path(room)
    match = create(:arena_match, :live, arena_room: room)
    create(:arena_participation, arena_match: match, character:, user:)

    get arena_room_path(other_room)

    expect(response).to redirect_to(arena_match_path(match))
    expect(character.reload.gameplay_context.dig("params", "room_id")).to eq(room.id)
  end

  it "restores a valid selected room on a fresh login with no city entry cookie" do
    sign_out user
    Game::World::ResumeContext.new(character:).remember_arena_room!(room:)

    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}

    expect(response).to redirect_to(arena_room_path(room))
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(room.name)
    expect(character.reload.gameplay_context.dig("params", "room_id")).to eq(room.id)
  end

  it "falls back to the world after login if the saved room belongs to a previous city" do
    sign_out user
    Game::World::ResumeContext.new(character:).remember_arena_room!(room:)
    other_city = create(:zone, :city)
    create(:city_hotspot, :arena, zone: other_city)
    position.update!(zone: other_city)

    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}

    expect(response).to redirect_to(world_path)
  end
end
