# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Solo NPC defeat experience", type: :request do
  it "finalizes 605 damage/57 XP once and renders and publishes the losing player's actual result on Finish" do
    player = create(:character, level: 17, current_hp: 0, in_combat: true)
    create(:character_position, character: player)
    match = create(:arena_match, :live, metadata: {
      "source" => "world_npc", "is_npc_fight" => true,
      "encounter_experience_reward" => 5000, "encounter_defeat_experience_reward" => 57
    })
    side = create(:arena_participation, arena_match: match, character: player, user: player.user, team: "a",
      metadata: {"damage_dealt" => 605, "opponents_defeated" => 1})
    create(:arena_participation, :npc, arena_match: match, team: "b", result: :defeat,
      metadata: {"current_hp" => 0, "max_hp" => 605})
    2.times { create(:arena_participation, :npc, arena_match: match, team: "b") }
    sign_in player.user

    expect(Arena::CombatProcessor.new(match).end_match("b")).to be(true)
    expect(player.reload.experience).to eq(57)
    expect(side.reload).to be_defeat
    expect(match.reload.metadata.dig("rewards", "experience")).to include("character_id" => player.id, "amount" => 57)
    expect(player.metadata.to_h["npc_wins"].to_i).to eq(0)
    expect(player.metadata.to_h["npc_losses"]).to eq(1)
    expect(GameEvent.where(recipient: player.user, event_type: :fight_finished)).to be_empty
    expect(Arena::CombatProcessor.new(match).end_match("b")).to be(false)

    get arena_match_path(match)
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    row = document.at_css(".nl-fight-result-table tbody tr")
    expect(row.css("td").map(&:text)).to eq(["#{player.name}[17]", "605(1)", "0", "605(1)", "57"])
    expect(document.at_css(".arena-result-title").text.strip).to eq("Defeat")

    2.times do
      post finish_arena_match_path(match)
      expect(response).to have_http_status(:see_other)
    end

    event = GameEvent.where(recipient: player.user, event_type: :fight_finished).sole
    expect(event.payload).to include("character_id" => player.id, "experience" => 57, "result" => "defeat", "winning_team" => "b")
    expect(player.reload.experience).to eq(57)
    expect(player.metadata.to_h["npc_losses"]).to eq(1)
    expect(side.reload.metadata["finished_at"]).to be_present
    expect(player).not_to be_in_combat
  end
end
