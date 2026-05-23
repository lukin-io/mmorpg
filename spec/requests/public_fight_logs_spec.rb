# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public fight logs", type: :request do
  let(:room) { create(:arena_room, name: "Тренировочный Зал", slug: "training") }
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, name: "max_kerby") }
  let(:npc) { create(:npc_template, name: "Манекен", npc_key: "training_mannequin") }
  let(:match) { create(:arena_match, :completed, arena_room: room, match_type: :duel, winning_team: "a") }
  let!(:player_participation) do
    create(:arena_participation, arena_match: match, character: character, user: user, team: "a")
  end
  let!(:npc_participation) do
    create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b")
  end

  before do
    create(:combat_log_entry,
      arena_match: match,
      actor: player_participation,
      target: npc_participation,
      log_type: "damage",
      round_number: 1,
      sequence: 1,
      message: "max_kerby бьет Манекен (Корпус): 6 урона [14/20]",
      damage_amount: 6,
      body_part: "torso",
      tags: %w[damage arena torso])
  end

  it "renders a public Neverlands-style fight log from durable entries" do
    get public_fight_log_path(match)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Лог боя ##{match.id}")
    expect(response.body).to include("max_kerby бьет Манекен")
  end

  it "exports log entries as JSON" do
    get public_fight_log_path(match, format: :json)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["fight_id"]).to eq(match.id)
    expect(body["entries"].first["description"]).to include("Манекен")
  end

  it "renders statistics from the same fight log entries" do
    get public_fight_log_path(match, stat: 1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("max_kerby")
    expect(response.body).to include("<td>6</td>")
  end
end
