# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Arena opponent selection", type: :request do
  let(:player) { create(:character, current_hp: 100, max_hp: 100) }
  let(:match) { create(:arena_match, status: :live, started_at: Time.current, current_turn_number: 1) }
  let!(:side) { create(:arena_participation, arena_match: match, character: player, user: player.user, team: "a") }
  let!(:opponents) { Array.new(3) { create(:arena_participation, :npc, arena_match: match, team: "b") } }

  before do
    create(:character_position, character: player)
    sign_in player.user
  end

  it "persists the selected member, spends two switches once each, and rejects stale or exhausted requests" do
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:ok)
    expect(side.reload.metadata).to include("selected_target_participation_id" => opponents[1].id, "opponent_switches_used" => 1)
    get arena_match_path(match)
    expect(response.body).to include("Switch opponent (1)")

    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(side.reload.metadata["opponent_switches_used"]).to eq(1)
    post switch_opponent_arena_match_path(match), params: {switches_used: 1}, as: :json
    expect(response).to have_http_status(:ok)
    expect(side.reload.metadata["selected_target_participation_id"]).to eq(opponents[2].id)
    post switch_opponent_arena_match_path(match), params: {switches_used: 2}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(side.reload.metadata["opponent_switches_used"]).to eq(2)
    expect(match.reload.current_turn_number).to eq(1)
    expect(player.reload.current_hp).to eq(100)
    get arena_match_path(match)
    expect(response.body).not_to include("Switch opponent (")
  end

  it "does not permit a forged turn target to bypass the exhausted allowance" do
    side.update!(metadata: {"selected_target_participation_id" => opponents.last.id, "opponent_switches_used" => 2})
    initial = side.metadata.deep_dup
    post action_arena_match_path(match), params: {
      action_type: "turn", target_id: "npc-participation-#{opponents.first.id}", turn_number: 1,
      attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
    }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to include("No opponent switches remain")
    expect(side.reload.metadata.except("combat_profile")).to eq(initial)
    expect(match.reload.current_turn_number).to eq(1)
    expect(match.combat_log_entries).to be_empty
  end

  it "automatically hands off a defeated selection without restoring or spending manual switches" do
    side.update!(metadata: {"selected_target_participation_id" => opponents.last.id, "opponent_switches_used" => 2})
    opponents.last.update!(metadata: {"current_hp" => 0, "max_hp" => 100})
    opponents.first.update!(metadata: {"current_hp" => 100, "max_hp" => 100})
    get arena_match_path(match)

    expect(response.body).to include("data-arena-match-selected-target-id-value=\"npc-participation-#{opponents.first.id}\"")
    expect(response.body).not_to include("Switch opponent (")
    expect(side.reload.metadata["opponent_switches_used"]).to eq(2)
    expect(side.selected_opponent(opponents: opponents.reverse)).to eq(opponents.first)

    document = Nokogiri::HTML(response.body)
    expect(document.css(".fighter-card[data-current-hp='0']")).to be_empty
    expect(document.css(".fighter-card--right").size).to eq(2)
    target_id = document.at_css(".arena-match-page")["data-arena-match-selected-target-id-value"]
    post action_arena_match_path(match), params: {
      action_type: "turn", target_id:, turn_number: 1,
      attacks: [{action_key: "simple", body_part: "head"}],
      blocks: [{action_key: "head_block", body_parts: ["head"]}]
    }, as: :json
    expect(response).to have_http_status(:ok)
    expect(match.reload.current_turn_number).to eq(2)
    expect(side.reload.metadata["opponent_switches_used"]).to eq(2)
  end

  it "omits defeated players and NPCs from live fighter cards while retaining their participation records" do
    defeated_player = create(:character, current_hp: 0, max_hp: 100)
    create(:arena_participation, arena_match: match, character: defeated_player, user: defeated_player.user, team: "b", result: :defeat)
    opponents.first.update!(result: :defeat, metadata: {"current_hp" => 0})

    get arena_match_path(match)

    document = Nokogiri::HTML(response.body)
    expect(document.css(".fighter-card--right").size).to eq(2)
    expect(document.css(".fighter-card[data-current-hp='0']")).to be_empty
    expect(match.arena_participations.count).to eq(5)
    expect(match.arena_participations.where(result: :defeat).count).to eq(2)
  end

  it "denies an anonymous or foreign user without mutating the selection" do
    sign_out player.user
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}
    expect(response).to redirect_to(new_user_session_path)
    stranger = create(:character)
    create(:character_position, character: stranger)
    sign_in stranger.user
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(side.reload.metadata["selected_target_participation_id"]).to be_nil
  end

  it "keeps recovered defeated players and NPCs out of live targeting and HTML/JSON rosters" do
    recovered = create(:character, current_hp: 90, max_hp: 100)
    fallen = create(:arena_participation, arena_match: match, character: recovered, user: recovered.user, team: "b", result: :defeat)
    opponents.first.update!(result: :defeat, metadata: {"current_hp" => 100, "max_hp" => 100})
    side.update!(metadata: {"selected_target_participation_id" => fallen.id})
    get arena_match_path(match)
    document = Nokogiri::HTML(response.body)
    expect(document.css(".fighter-card--right").size).to eq(2)
    expect(document.css("[data-roster-id='#{recovered.id}']")).to be_empty
    expect(document.css("[data-roster-id='npc-participation-#{opponents.first.id}']")).to be_empty
    expect(document.at_css(".arena-match-page")["data-arena-match-selected-target-id-value"]).to eq("npc-participation-#{opponents.second.id}")

    get arena_match_path(match), as: :json
    defeated = response.parsed_body.fetch("participants").select { |entry| entry["result"] == "defeat" }
    expect(defeated.size).to eq(2)
    expect(defeated).to all(include("current_hp" => 0, "is_dead" => true))
    expect(recovered.reload.current_hp).to eq(90)
    expect(match.arena_participations.count).to eq(5)

    turn = {action_type: "turn", turn_number: 1,
            attacks: [{action_key: "simple", body_part: "head"}],
            blocks: [{action_key: "head_block", body_parts: ["head"]}]}
    post action_arena_match_path(match), params: turn.merge(target_id: recovered.id), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(match.reload.current_turn_number).to eq(1)
    post action_arena_match_path(match), params: turn.merge(target_id: "npc-participation-#{opponents.second.id}"), as: :json
    expect(response).to have_http_status(:ok)
    expect(match.reload.current_turn_number).to eq(2)
    expect(fallen.reload.metadata["pending_turn"]).to be_nil
  end

  it "rejects a recovered defeated player's turn and switch without changing the current round" do
    side.update!(result: :defeat, metadata: {"pending_turn" => {"turn_number" => 1}})
    create(:arena_participation, arena_match: match, team: "a")
    initial = side.metadata.deep_dup
    post action_arena_match_path(match), params: {
      action_type: "turn", turn_number: 1, target_id: "npc-participation-#{opponents.first.id}",
      attacks: [{action_key: "simple", body_part: "head"}],
      blocks: [{action_key: "head_block", body_parts: ["head"]}]
    }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to include("defeated")
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to include("defeated")
    expect(side.reload.metadata).to eq(initial)
    expect(match.reload.current_turn_number).to eq(1)
    expect(match.combat_log_entries).to be_empty
    expect(player.reload.current_hp).to eq(100)

    get arena_match_path(match), as: :json
    expect(response.parsed_body).to include("current_user_waiting" => false)
    get arena_match_path(match)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css(".arena-match-page")["data-arena-match-waiting-value"]).to eq("false")
  end

  it "projects a positive solo-NPC completion into private chat on Finish exactly once" do
    opponents.each { |npc| npc.update!(result: :defeat, metadata: {"current_hp" => 0}) }
    match.update!(metadata: {"encounter_experience_reward" => 5})
    expect { Arena::CombatProcessor.new(match).end_match("a") }.not_to change { GameEvent.where(event_type: :fight_finished).count }
    expect(match.reload.metadata.dig("rewards", "experience", "amount")).to eq(5)

    get arena_match_path(match)
    document = Nokogiri::HTML(response.body)
    expect(document.css(".arena-fighter--right .fighter-card")).to be_empty
    expect(document.css("[data-arena-match-target='rosterParticipant']")).to be_empty
    expect(document.css(".arena-fighter--left .fighter-card").size).to eq(1)
    expect(document.css(".arena-combat-log strong.nl-log-name")).not_to be_empty
    expect(match.arena_participations.npcs.count).to eq(3)

    expect { post finish_arena_match_path(match) }.to change { GameEvent.where(event_type: :fight_finished).count }.by(1)
    event = GameEvent.find_by!(event_type: :fight_finished)
    expect(event.recipient_id).to eq(player.user_id)
    expect(event.payload["experience"]).to eq(5)
    expect { post finish_arena_match_path(match) }.not_to change { GameEvent.where(event_type: :fight_finished).count }
  end

  it "rejects switching while waiting or after defeat without consuming the allowance" do
    side.update!(metadata: {"pending_turn" => {"turn_number" => 1}})
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(side.reload.metadata["opponent_switches_used"]).to be_nil
    side.update!(metadata: {})
    player.update!(current_hp: 0)
    post switch_opponent_arena_match_path(match), params: {switches_used: 0}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(side.reload.metadata["opponent_switches_used"]).to be_nil
  end
end
