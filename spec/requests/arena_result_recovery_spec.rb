# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Physical Arena result recovery", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:, level: 10) }
  let(:city) { create(:zone, :city) }
  let!(:position) { create(:character_position, character:, zone: city) }
  let!(:hotspot) { create(:city_hotspot, :arena, zone: city) }
  let(:room) { create(:arena_room, zone: city) }
  let(:match) { create(:arena_match, :team_battle, :completed, arena_room: room, metadata: {physical_only: true}) }
  let!(:participation) { create(:arena_participation, :defeat, arena_match: match, character:, user:) }

  before { sign_in user }

  it "restores an offline player's result on login and keeps navigation there until Finish" do
    sign_out user
    post user_session_path, params: {user: {email: user.email, password: "Password123!"}}
    expect(response).to redirect_to(arena_match_path(match))
    [world_path, arena_index_path, arena_room_path(room)].each do |path|
      get path
      expect(response).to redirect_to(arena_match_path(match))
    end

    post finish_arena_match_path(match)
    expect(response).to redirect_to(arena_room_path(room, ft: 2))
    timestamp = participation.reload.metadata.fetch("finished_at")
    expect(character.reload.unfinished_arena_result).to be_nil
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Submit Application")

    post finish_arena_match_path(match)
    expect(participation.reload.metadata.fetch("finished_at")).to eq(timestamp)
  end

  it "rejects new applications and group joins before acknowledging the previous result" do
    post arena_room_arena_applications_path(room), params: {arena_application: {fight_type: "duel"}}, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(character.arena_applications).to be_empty

    owner = create(:character, level: 10)
    create(:character_position, character: owner, zone: city)
    application = create(:arena_application, :team_battle, applicant: owner, arena_room: room)
    application.arena_application_memberships.create!(character: owner, team: "a")
    post accept_arena_application_path(application), params: {team: "b"}, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(application.arena_application_memberships.where(character:)).to be_empty
  end

  it "does not clear a newer fight when an old Finish is replayed" do
    participation.update!(metadata: {finished_at: 1.minute.ago.iso8601})
    active_match = create(:arena_match, :live, arena_room: room, metadata: {physical_only: true})
    create(:arena_participation, arena_match: active_match, character:, user:)
    character.update!(in_combat: true)

    post finish_arena_match_path(match)

    expect(character.reload).to be_in_combat
    expect(active_match.reload).to be_live
    expect(participation.reload.metadata.fetch("finished_at")).to be_present
  end

  it "falls back safely when the previous room is no longer accessible" do
    room.update!(active: false)
    post finish_arena_match_path(match)
    expect(response).to redirect_to(arena_index_path)
    expect(character.reload.unfinished_arena_result).to be_nil
  end

  it "keeps historical and other players' results out of the resume gate" do
    match.update!(metadata: {})
    other_match = create(:arena_match, :completed, metadata: {physical_only: true})
    create(:arena_participation, arena_match: other_match)

    expect(character.reload.unfinished_arena_result).to be_nil
    get world_path
    expect(response).to have_http_status(:ok)
  end
end
