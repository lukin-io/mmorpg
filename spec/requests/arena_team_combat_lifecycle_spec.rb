# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Physical 3x3 team combat lifecycle", type: :request do
  include ActiveJob::TestHelper

  let(:arena_room) do
    create(
      :arena_room,
      :trial,
      name: "Synthetic Team Hall",
      level_min: 1,
      level_max: 100,
      max_concurrent_matches: 5
    )
  end

  before do
    @teams = %w[a b].index_with do |team|
      3.times.map do |index|
        user = create(
          :user,
          email: "synthetic-#{team}#{index + 1}@browser-rpg.test",
          profile_name: "synthetic_#{team}#{index + 1}"
        )
        character = create(
          :character,
          user:,
          name: "Synthetic#{team.upcase}#{index + 1}",
          level: 10,
          current_hp: 10_000,
          max_hp: 10_000,
          in_combat: true
        )
        create(:character_position, character:)
        {user:, character:}
      end
    end

    @match = create(
      :arena_match,
      :team_battle,
      :live,
      arena_room:,
      turn_timeout_seconds: 300
    )
    @participations = @teams.to_h do |team, players|
      participations = players.map do |player|
        create(
          :arena_participation,
          arena_match: @match,
          user: player.fetch(:user),
          character: player.fetch(:character),
          team:
        )
      end
      [team, participations]
    end

    allow(Arena::CombatProcessor).to receive(:new).and_wrap_original do |original, match, **kwargs|
      original.call(match, **kwargs.merge(rng: Random.new(20_260_901)))
    end
  end

  it "waits for all six legal turns, resolves once, rejects stale replay, completes one side, and finishes everyone" do
    side_a = @teams.fetch("a")
    side_b = @teams.fetch("b")
    targets = [side_b[1], side_b[2], side_b[0], side_a[1], side_a[2], side_a[0]]
    players = side_a + side_b

    with_signed_in(side_a.first.fetch(:user)) do
      post action_arena_match_path(@match),
        params: physical_turn(target: side_a[1].fetch(:character), turn_number: 1),
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("error")).to eq("Cannot attack an ally")
      expect(@participations.fetch("a").first.reload.metadata["pending_turn"]).to be_blank
    end

    players.each_with_index do |player, index|
      with_signed_in(player.fetch(:user)) do
        post action_arena_match_path(@match),
          params: physical_turn(target: targets.fetch(index).fetch(:character), turn_number: 1),
          as: :json

        expect(response).to have_http_status(:ok)
        if index < players.length - 1
          expect(response.parsed_body.dig("data", "waiting")).to be(true)
          expect(response.parsed_body.dig("data", "resolved")).to be(false)
          expect(@match.reload.current_turn_number).to eq(1)
        else
          expect(response.parsed_body.dig("data", "waiting")).to be(false)
          expect(response.parsed_body.dig("data", "resolved")).to be(true)
        end

        next unless index.zero?

        participation = @participations.fetch("a").first.reload
        expect(participation.metadata.dig("pending_turn", "target_participation_id"))
          .to eq(@participations.fetch("b")[1].id)

        get arena_match_path(@match)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Waiting for opponent turn")
        expect(response.body).to include("SyntheticB2")

        post action_arena_match_path(@match),
          params: physical_turn(target: side_b[1].fetch(:character), turn_number: 1),
          as: :json
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.fetch("error")).to eq("Turn already submitted; waiting for opponent")
      end
    end

    expect(@match.reload).to be_live
    expect(@match.current_turn_number).to eq(2)
    expect(@match.arena_participations.reload.map { |entry| entry.metadata["pending_turn"] }).to all(be_blank)
    expect(@match.arena_participations.map { |entry| entry.metadata["current_ap"] })
      .to contain_exactly(*players.map { |player| player.fetch(:character).max_action_points })
    expect(
      @match.combat_log_entries.where(log_type: "action").where("message LIKE ?", "%submitted a turn%").count
    ).to eq(6)

    with_signed_in(side_a.first.fetch(:user)) do
      post action_arena_match_path(@match),
        params: physical_turn(target: side_b.first.fetch(:character), turn_number: 1),
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("error")).to eq("Fight state changed; refresh and submit the current turn")
      expect(@match.reload.current_turn_number).to eq(2)
      expect(@participations.fetch("a").first.reload.metadata["pending_turn"]).to be_blank
    end

    side_b.each_with_index do |player, index|
      with_signed_in(player.fetch(:user)) do
        post action_arena_match_path(@match), params: {action_type: "surrender"}, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig("data", "match_ended")).to eq(index == 2)
        expect(@match.reload.status).to eq(index == 2 ? "completed" : "live")
      end
    end

    expect(@match.reload.winning_team).to eq("a")
    expect(@participations.fetch("a").map { |entry| entry.reload.result }).to all(eq("victory"))
    expect(@participations.fetch("b").map { |entry| entry.reload.result }).to all(eq("defeat"))

    with_signed_in(side_a.first.fetch(:user)) do
      get arena_match_path(@match)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Victory")
      players.each { |player| expect(response.body).to include(player.fetch(:character).name) }
      expect(response.body).to include("Finish Fight")
    end

    players.each do |player|
      with_signed_in(player.fetch(:user)) do
        post finish_arena_match_path(@match)
        expect(response).to have_http_status(:see_other)
      end

      expect(player.fetch(:character).reload).not_to be_in_combat
      participation = @match.arena_participations.find_by!(character: player.fetch(:character))
      expect(participation.metadata["finished_at"]).to be_present
    end

    finished_at = @participations.fetch("a").first.reload.metadata.fetch("finished_at")
    with_signed_in(side_a.first.fetch(:user)) do
      post finish_arena_match_path(@match)
      expect(response).to have_http_status(:see_other)
    end
    expect(@participations.fetch("a").first.reload.metadata.fetch("finished_at")).to eq(finished_at)

    get public_fight_log_path(@match)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Fight participants:")
    players.each { |player| expect(response.body).to include(player.fetch(:character).name) }

    get public_fight_log_path(@match, stat: 1, format: :json)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("participants").size).to eq(6)
    expect(response.parsed_body.fetch("teams").keys).to contain_exactly("a", "b")
  end

  private

  def physical_turn(target:, turn_number:)
    {
      action_type: "turn",
      turn_number:,
      target_id: target.id,
      attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "head_block", body_parts: ["head"]}]
    }
  end

  def with_signed_in(user)
    sign_in user, scope: :user
    yield
  ensure
    sign_out user
  end
end
