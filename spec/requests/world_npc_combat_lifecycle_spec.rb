# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Physical wilderness NPC combat lifecycle", type: :request do
  let(:user) { create(:user) }
  let(:character) do
    create(
      :character,
      user:,
      name: "RatHunter",
      level: 4,
      current_hp: 500,
      max_hp: 500,
      metadata: {"npc_wins" => 7}
    )
  end
  let(:zone) do
    create(
      :zone,
      name: "Outpost Surroundings",
      location_type: "outdoor",
      width: 1_000,
      height: 1_000
    )
  end
  let!(:position) { create(:character_position, character:, zone:, x: 7, y: 7) }
  let(:npc_template) do
    create(
      :npc_template,
      npc_key: "plague_rat",
      name: "Plague Rat",
      role: "hostile",
      level: 4,
      metadata: {
        "health" => 5,
        "base_damage" => 1,
        "ai_behavior" => "passive",
        "xp_reward" => 35,
        "loot_table" => [
          {"kind" => "item", "item_key" => "rat_tail", "item_name" => "Rat Tail", "chance" => 0.0}
        ]
      }
    )
  end
  let!(:tile_npc) do
    create(
      :tile_npc,
      :multi_npc_encounter,
      npc_template:,
      npc_key: "plague_rat",
      zone: zone.name,
      x: 7,
      y: 7,
      current_hp: 5,
      max_hp: 5
    )
  end
  let(:turn_params) do
    {
      action_type: "turn",
      attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
    }
  end
  let(:hit_result) do
    {
      outcome: :hit,
      hit: true,
      miss: false,
      dodge: false,
      blocked: false,
      critical: false,
      damage: 1_000,
      action_key: "simple",
      body_part: "torso",
      hit_roll: 1,
      hit_chance: 95,
      dodge_roll: 99,
      dodge_chance: 5,
      crit_roll: 99,
      crit_chance: 10,
      block_key: nil,
      block_table: nil,
      block_attempted: false,
      block_success: false,
      block_roll: nil,
      block_chance: nil
    }
  end

  before do
    sign_in user, scope: :user
    stub_const("Game::World::PassiveEncounterCheck::MIN_DELAY_SECONDS", 0)
    stub_const("Game::World::PassiveEncounterCheck::MAX_DELAY_SECONDS", 0)
    allow_any_instance_of(Arena::CombatResolver).to receive(:resolve_physical_attack).and_return(hit_result)
    defend = Arena::NpcCombatAi::Decision.new(action_type: :defend, target: nil, params: {})
    allow(Arena::NpcCombatAi).to receive(:new)
      .and_return(instance_double(Arena::NpcCombatAi, decide_action: defend))
  end

  it "runs passive start, 1xN target handoff, per-NPC search, one result reward, finish, and reload" do
    post world_encounter_check_path, as: :json
    expect(response.parsed_body).to include("interrupted" => false, "retry_after_ms" => 1_000)

    post world_encounter_check_path, as: :json

    expect(response).to have_http_status(:ok)
    match = ArenaMatch.last
    npcs = match.arena_participations.npcs.order(:id).to_a
    player = match.arena_participations.players.find_by!(character:)
    expect(match).to be_live
    expect(npcs.size).to eq(2)
    expect(match.metadata["encounter_experience_reward"]).to eq(35)
    expect(character.reload).to be_in_combat

    get arena_match_path(match)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Plague Rat")
    expect(response.body).to include("[5/5]")

    post action_arena_match_path(match),
      params: turn_params.merge(
        turn_number: 1,
        target_id: "npc-participation-#{npcs.first.id}"
      ),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(match.reload).to be_live
    expect(npcs.first.reload).to be_defeat
    expect(npcs.second.reload.current_hp).to eq(5)
    expect(tile_npc.reload).to be_alive
    expect(character.reload.metadata["npc_wins"]).to eq(7)
    expect(match.combat_log_entries.where(log_type: "loot").count).to eq(1)
    expect(match.current_turn_number).to eq(2)
    expect(player.reload.metadata["current_ap"]).to eq(character.max_action_points)

    first_turn_log_count = match.combat_log_entries.count
    post action_arena_match_path(match),
      params: turn_params.merge(
        turn_number: 1,
        target_id: "npc-participation-#{npcs.first.id}"
      ),
      as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to eq("Fight state changed; refresh and submit the current turn")
    expect(match.combat_log_entries.count).to eq(first_turn_log_count)
    expect(npcs.second.reload.current_hp).to eq(5)

    get arena_match_path(match)

    target_line = Nokogiri::HTML(response.body).at_css(".nl-fight-target-line")
    expect(target_line.text.squish).to include("Plague Rat [5/5]")
    expect(target_line.text.squish).not_to include("[0/5]")

    post action_arena_match_path(match),
      params: turn_params.merge(
        turn_number: 2,
        target_id: "npc-participation-#{npcs.second.id}"
      ),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(match.reload).to be_completed
    expect(match.winning_team).to eq("a")
    expect(match.combat_log_entries.where(log_type: "loot").count).to eq(2)
    expect(match.combat_log_entries.where(log_type: "victory").count).to be >= 1
    expect(match.combat_log_entries.where(log_type: %w[damage critical]).pluck(:message).join(" ")).to include("for -1000")
    expect(player.reload.metadata["damage_dealt"]).to eq(10)
    expect(player.metadata["damage_hits"]).to eq(2)
    expect(npcs.sum { |npc| npc.reload.metadata["damage_taken"].to_i }).to eq(10)
    expect(character.reload.experience).to eq(35)
    expect(character.metadata["npc_wins"]).to eq(8)
    expect(tile_npc.reload).to be_defeated
    expect(match.metadata.dig("rewards", "experience", "amount")).to eq(35)

    get arena_match_path(match)

    result_table = Nokogiri::HTML(response.body).at_css(".nl-fight-result-table")
    expect(result_table.text.squish).to include("RatHunter[4] 10(2) 10(2) 35")
    expect(response.body).to include("Finish Fight")

    post finish_arena_match_path(match)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(world_path)
    expect(character.reload).not_to be_in_combat

    get world_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-game-layout-encounter-url-value")

    expect {
      post finish_arena_match_path(match)
    }.not_to change { character.reload.metadata["npc_wins"] }
    expect(response).to redirect_to(world_path)
  end
end
