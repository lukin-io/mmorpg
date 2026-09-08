# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public fight logs", type: :request do
  let(:room) { create(:arena_room, name: "Training Hall", slug: "training") }
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, name: "max_kerby") }
  let(:npc) { create(:npc_template, name: "Training Dummy", npc_key: "training_mannequin") }
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
      message: "max_kerby hits Training Dummy (Torso): 6 damage [14/20]",
      damage_amount: 6,
      body_part: "torso",
      tags: %w[damage arena torso])
  end

  it "renders a public Neverlands-style fight log from durable entries" do
    get public_fight_log_path(match)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fight Log ##{match.id}")
    expect(Nokogiri::HTML(response.body).text.squish).to include("max_kerby hits Training Dummy")
    expect(response.body).to include("nl-public-layout--fight-log")
    expect(response.body).not_to include("nl-game-layout")
    expect(response.body).not_to include("Neverlands administration")
    expect(response.body).not_to include("assets/neverlands")
    expect(response.body).to include("Statistics")
  end

  it "exports log entries as JSON" do
    get public_fight_log_path(match, format: :json)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["fight_id"]).to eq(match.id)
    expect(body["entries"].first["description"]).to include("Training Dummy")
  end

  it "renders statistics from the same fight log entries" do
    get public_fight_log_path(match, stat: 1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("max_kerby")
    expect(response.body).to include("<td>6</td>")
    expect(response.body).to include("Fight log")
  end

  it "paginates the durable chronological stream at fifty entries" do
    (2..52).each do |sequence|
      create(
        :combat_log_entry,
        arena_match: match,
        actor: player_participation,
        target: npc_participation,
        round_number: 1,
        sequence:,
        message: format("Synthetic event %02d", sequence)
      )
    end

    get public_fight_log_path(match)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Synthetic event 50")
    expect(response.body).not_to include("Synthetic event 51")
    expect(response.body).to include(public_fight_log_path(match, p: 2))

    get public_fight_log_path(match, p: 2)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Synthetic event 51")
    expect(response.body).to include("Synthetic event 52")
    expect(response.body).not_to include("Synthetic event 50")
  end

  it "renders an explicit empty state and normalizes a non-positive page" do
    empty_match = create(:arena_match, :completed, arena_room: room)

    get public_fight_log_path(empty_match, p: 0)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No fight events recorded.")
    expect(response.body).to include("Fight participants:")

    get public_fight_log_path(empty_match, p: -4, format: :json)
    expect(response.parsed_body.fetch("current_page")).to eq(1)
    expect(response.parsed_body.fetch("entries")).to eq([])
  end

  it "returns bounded HTML and JSON errors for a missing fight" do
    missing_id = ArenaMatch.maximum(:id).to_i + 10_000

    get public_fight_log_path(missing_id)
    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("Fight log not found")

    get public_fight_log_path(missing_id, format: :json)
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("error" => "fight log not found")
  end

  it "escapes non-participant log text while adding participant color spans" do
    create(:combat_log_entry,
      arena_match: match,
      actor: player_participation,
      target: npc_participation,
      round_number: 1,
      sequence: 2,
      message: "max_kerby sees <script>alert('unsafe')</script>")

    get public_fight_log_path(match)

    expect(response.body).to include("nl-log-name--alpha")
    expect(response.body).to include("&lt;script&gt;alert(&#39;unsafe&#39;)&lt;/script&gt;")
    expect(response.body).not_to include("<script>alert('unsafe')</script>")
  end
end
