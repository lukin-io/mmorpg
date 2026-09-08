# frozen_string_literal: true

require "rails_helper"

RSpec.describe "World encounter checks", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, name: "Passive Encounter Woods", location_type: "outdoor") }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  before do
    sign_in user, scope: :user
    stub_const("Game::World::PassiveEncounterCheck::MIN_DELAY_SECONDS", 0)
    stub_const("Game::World::PassiveEncounterCheck::MAX_DELAY_SECONDS", 0)
  end

  it "starts the source-backed same-cell group through the shared fight pipeline" do
    npc = create(:tile_npc, :multi_npc_encounter, zone: zone.name, x: 5, y: 5)

    expect {
      post world_encounter_check_path, as: :json
    }.not_to change(ArenaMatch, :count)
    expect(response.parsed_body).to include(
      "interrupted" => false,
      "retry_after_ms" => 1_000
    )

    expect {
      post world_encounter_check_path, as: :json
    }.to change(ArenaMatch, :count).by(1)
      .and change(ArenaParticipation, :count).by(3)

    match = ArenaMatch.last
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "interrupted" => true,
      "redirect_url" => arena_match_path(match)
    )
    expect(response.parsed_body["message"]).to include(npc.display_name)
    expect(match).to be_live
    expect(match.metadata).to include(
      "source" => "world_npc",
      "encounter_count" => 2,
      "return_context" => {"name" => "world"}
    )
  end

  it "starts one complete mixed roster sample without accepting client roster inputs" do
    bandit = create(
      :npc_template,
      npc_key: "request-bandit",
      name: "Request Bandit",
      level: 7,
      metadata: {"health" => 155, "base_damage" => 3}
    )
    robber = create(
      :npc_template,
      npc_key: "request-robber",
      name: "Request Robber",
      level: 8,
      metadata: {"health" => 270, "base_damage" => 4}
    )
    create(
      :tile_npc,
      npc_template: bandit,
      npc_key: bandit.npc_key,
      zone: zone.name,
      x: 5,
      y: 5,
      metadata: {
        "encounter_rosters" => [
          {
            "key" => "captured-mixed",
            "encounter_experience_reward" => 56,
            "trauma_percent" => 30,
            "members" => [
              {"npc_key" => bandit.npc_key, "level" => 8, "hp" => 185},
              {"npc_key" => robber.npc_key, "level" => 9, "hp" => 310}
            ]
          }
        ]
      }
    )

    post world_encounter_check_path, params: {npc_key: "forged", group_size: 8}, as: :json
    post world_encounter_check_path, params: {npc_key: "forged", group_size: 8}, as: :json

    match = ArenaMatch.last
    participants = match.arena_participations.npcs.order(:id)
    expect(response).to have_http_status(:ok)
    expect(match.metadata).to include(
      "encounter_roster_sample" => "captured-mixed",
      "encounter_member_keys" => [bandit.npc_key, robber.npc_key],
      "encounter_experience_reward" => 56
    )
    expect(participants.map(&:participant_level)).to eq([8, 9])
    expect(participants.map(&:max_hp)).to eq([185, 310])
  end

  it "returns the same active fight when the browser retries the check" do
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    post world_encounter_check_path, as: :json
    post world_encounter_check_path, as: :json
    first_match = ArenaMatch.find_by!(id: response.parsed_body.fetch("redirect_url").split("/").last)

    expect {
      post world_encounter_check_path, as: :json
    }.not_to change(ArenaMatch, :count)

    expect(response.parsed_body["redirect_url"]).to eq(arena_match_path(first_match))
  end

  it "does not invent an encounter without an alive hostile on the current outdoor cell" do
    defeated = create(:tile_npc, :defeated, zone: zone.name, x: 5, y: 5)

    post world_encounter_check_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "interrupted" => false,
      "retry_after_ms" => 30_000
    )
    expect(ArenaMatch.count).to eq(0)
    expect(defeated.reload).to be_defeated
  end

  it "does not start wilderness combat from a city position" do
    zone.update!(location_type: "city")
    create(:tile_npc, zone: zone.name, x: 5, y: 5)

    post world_encounter_check_path, as: :json

    expect(response.parsed_body).to eq(
      "interrupted" => false,
      "retry_after_ms" => 30_000
    )
    expect(ArenaMatch.count).to eq(0)
  end

  it "returns a bounded failure without creating a partial match" do
    create(:tile_npc, zone: zone.name, x: 5, y: 5)
    allow_any_instance_of(Game::World::StartNpcFight).to receive(:call)
      .and_raise(Game::World::StartNpcFight::FightViolationError, "Combat startup failed.")

    post world_encounter_check_path, as: :json

    expect {
      post world_encounter_check_path, as: :json
    }.not_to change(ArenaMatch, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to eq(
      "interrupted" => false,
      "error" => "Combat startup failed."
    )
  end

  it "requires authentication" do
    sign_out user

    post world_encounter_check_path, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(ArenaMatch.count).to eq(0)
  end
end
