# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Physical 1x1 PvP lifecycle", type: :request do
  include ActiveJob::TestHelper

  let(:first_user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:first_character) do
    create(:character, user: first_user, level: 10, current_hp: 1_000, max_hp: 1_000)
  end
  let(:second_character) do
    create(:character, user: second_user, level: 10, current_hp: 1_000, max_hp: 1_000)
  end
  let(:arena_room) do
    create(
      :arena_room,
      :trial,
      name: "PvP Lifecycle Hall",
      level_min: 1,
      level_max: 100,
      max_concurrent_matches: 5
    )
  end
  let(:turn_params) do
    {
      action_type: "turn",
      attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
    }
  end

  before do
    create(:character_position, character: first_character)
    create(:character_position, character: second_character)
    allow(Arena::CombatProcessor).to receive(:new).and_wrap_original do |original, match, **kwargs|
      original.call(match, **kwargs.merge(rng: Random.new(12_345)))
    end
  end

  it "runs create, accept, start, shared round, surrender, both finishes, and replay" do
    sign_in first_user
    enter_arena_from_city!(first_character)

    post arena_room_arena_applications_path(arena_room),
      params: {
        arena_application: {
          fight_type: "duel",
          fight_kind: "free",
          timeout_seconds: 180,
          trauma_percent: 30
        }
      },
      as: :json

    expect(response).to have_http_status(:created)
    application = ArenaApplication.find(response.parsed_body.dig("application", "id"))
    expect(application).to be_open

    sign_out first_user
    sign_in second_user
    enter_arena_from_city!(second_character)

    post accept_arena_application_path(application), as: :json

    expect(response).to have_http_status(:ok)
    match = ArenaMatch.find(response.parsed_body.fetch("match_id"))
    expect(match).to be_pending
    expect(match.arena_applications.count).to eq(2)
    expect(match.arena_applications).to all(be_matched)

    Arena::MatchStarterJob.perform_now(match.id)

    expect(match.reload).to be_live
    expect(match.current_turn_number).to eq(1)
    expect(match.arena_applications.reload).to all(be_started)
    expect([first_character.reload.in_combat?, second_character.reload.in_combat?]).to all(be(true))

    post action_arena_match_path(match),
      params: turn_params.merge(target_id: first_character.id),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "waiting")).to be(true)
    second_participation = match.arena_participations.find_by!(user: second_user)
    expect(second_participation.reload.metadata["pending_turn"]).to be_present

    sign_out second_user
    sign_in first_user

    post action_arena_match_path(match),
      params: turn_params.merge(target_id: second_character.id),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "resolved")).to be(true)
    expect(match.reload).to be_live
    expect(match.current_turn_number).to eq(2)
    expect(match.arena_participations.reload.map { |entry| entry.metadata["pending_turn"] }).to all(be_blank)
    expect(match.combat_log_entries.where(log_type: "action").count).to be >= 2

    post action_arena_match_path(match), params: {action_type: "surrender"}, as: :json

    expect(response).to have_http_status(:ok)
    expect(match.reload).to be_completed
    expect(match.winning_team).to eq("b")
    expect(match.arena_participations.find_by!(user: first_user)).to be_defeat
    expect(match.arena_participations.find_by!(user: second_user)).to be_victory

    post finish_arena_match_path(match)

    expect(response).to have_http_status(:see_other)
    expect(first_character.reload).not_to be_in_combat

    sign_out first_user
    sign_in second_user
    post finish_arena_match_path(match)

    expect(response).to have_http_status(:see_other)
    expect(second_character.reload).not_to be_in_combat
    expect(match.arena_participations.reload.map { |entry| entry.metadata["finished_at"] }).to all(be_present)

    expect do
      post arena_room_arena_applications_path(arena_room),
        params: {
          arena_application: {
            fight_type: "duel",
            fight_kind: "free",
            timeout_seconds: 180,
            trauma_percent: 30
          }
        },
        as: :json
    end.to change(ArenaApplication.open, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(ArenaApplication.active.where(applicant: second_character).count).to eq(1)
  end

  private

  def enter_arena_from_city!(character)
    zone = character.position.zone
    zone.update!(location_type: "city")
    hotspot = create(:city_hotspot, :arena, zone:, active: true, required_level: 1)
    offer = create(
      :world_action_offer,
      character:,
      zone:,
      x: character.position.x,
      y: character.position.y,
      action_type: "enter_city_building",
      target: hotspot
    )

    post interact_hotspot_world_path,
      params: {hotspot_id: hotspot.id, action_key: offer.action_key}
    expect(response).to have_http_status(:found)
  end
end
