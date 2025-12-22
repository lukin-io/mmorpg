# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# Arena NPC Combat Request Specs
# =============================================================================
# Comprehensive tests for arena NPC (bot) combat mechanics.
# Tests cover: accepting NPC applications, NPC fights, combat actions.
#
# Related docs:
#   - doc/flow/11_arena_pvp.md
#   - doc/flow/22_arena_npc_bots.md
#   - doc/flow/22_unified_npc_architecture.md
# =============================================================================

RSpec.describe "Arena NPC Combat", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, :with_position, user: user, level: 5, current_hp: 100, max_hp: 100) }
  let(:arena_room) { create(:arena_room, name: "Training Grounds", slug: "training", level_min: 1, level_max: 10, active: true) }
  let!(:arena_season) { create(:arena_season, :live) }

  let(:arena_bot) do
    create(:npc_template,
      npc_key: "arena_training_dummy",
      name: "Training Dummy",
      role: "arena_bot",
      level: 3,
      dialogue: "*creaks*",
      metadata: {
        "health" => 60,
        "base_damage" => 5,
        "difficulty" => "easy",
        "ai_behavior" => "defensive",
        "arena_rooms" => ["training"],
        "avatar" => "🎯",
        "stats" => {"attack" => 8, "defense" => 4, "hp" => 60}
      })
  end

  let(:npc_application) do
    create(:arena_application,
      arena_room: arena_room,
      applicant: nil,
      npc_template: arena_bot,
      status: :open,
      fight_type: :duel,
      fight_kind: :no_weapons)
  end

  before do
    sign_in user, scope: :user
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character)
  end

  # ===========================================================================
  # Accepting NPC Applications
  # ===========================================================================

  describe "POST /arena_applications/:id/accept (NPC application)" do
    context "success - accepting NPC bot application" do
      it "accepts the NPC application and creates a match" do
        post accept_arena_application_path(npc_application)

        expect(response).to redirect_to(arena_match_path(ArenaMatch.last))
        expect(ArenaMatch.count).to eq(1)
      end

      it "creates arena participations for both player and NPC" do
        expect {
          post accept_arena_application_path(npc_application)
        }.to change(ArenaParticipation, :count).by(2)

        match = ArenaMatch.last
        player_participation = match.arena_participations.find_by(character: character)
        npc_participation = match.arena_participations.find_by(npc_template: arena_bot)

        expect(player_participation).to be_present
        expect(player_participation.team).to eq("a")
        expect(npc_participation).to be_present
        expect(npc_participation.team).to eq("b")
      end

      it "marks the application as matched" do
        post accept_arena_application_path(npc_application)

        npc_application.reload
        expect(npc_application.status).to eq("matched")
      end

      it "sets match metadata with is_npc_fight flag" do
        post accept_arena_application_path(npc_application)

        match = ArenaMatch.last
        expect(match.metadata["is_npc_fight"]).to eq(true)
      end

      context "with JSON format" do
        it "returns success JSON with match details" do
          post accept_arena_application_path(npc_application), as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["match_id"]).to be_present
        end
      end
    end

    context "edge cases" do
      it "handles NPC with empty metadata gracefully" do
        arena_bot.update!(metadata: {"arena_rooms" => ["training"]})

        post accept_arena_application_path(npc_application)

        expect(response.status).to be_in([200, 302])
      end
    end
  end

  # ===========================================================================
  # Arena NPC Match Viewing
  # ===========================================================================

  describe "arena NPC match combat log" do
    let!(:arena_match) do
      create(:arena_match, :pending,
        arena_room: arena_room,
        arena_season: arena_season,
        match_type: :duel,
        metadata: {
          "is_npc_fight" => true,
          "combat_log" => [
            {"type" => "damage", "actor_name" => character.name, "description" => "attacks Training Dummy for 15 damage"},
            {"type" => "action", "actor_name" => "Training Dummy", "description" => "takes a defensive stance"}
          ]
        })
    end

    let!(:player_participation) do
      create(:arena_participation,
        arena_match: arena_match,
        character: character,
        user: user,
        team: "a",
        result: :pending)
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: arena_match,
        npc_template: arena_bot,
        team: "b",
        result: :pending,
        metadata: {"current_hp" => 60, "max_hp" => 60})
    end

    describe "GET /arena_matches/:id/log (combat log with NPC)" do
      it "returns combat log with NPC actions" do
        get log_arena_match_path(arena_match), as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["log"]).to be_an(Array)
        expect(json["log"].length).to eq(2)
      end
    end
  end

  # ===========================================================================
  # Arena::CombatProcessor NPC Detection
  # ===========================================================================

  describe "Arena::CombatProcessor npc_fight? detection" do
    let!(:arena_match) do
      create(:arena_match, :live,
        arena_room: arena_room,
        arena_season: arena_season,
        match_type: :duel,
        metadata: {"is_npc_fight" => true, "combat_log" => []})
    end

    let!(:player_participation) do
      create(:arena_participation,
        arena_match: arena_match,
        character: character,
        user: user,
        team: "a",
        result: :pending)
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: arena_match,
        npc_template: arena_bot,
        team: "b",
        result: :pending,
        metadata: {"current_hp" => 60, "max_hp" => 60})
    end

    it "detects NPC fight from metadata" do
      processor = Arena::CombatProcessor.new(arena_match)
      expect(processor.npc_fight?).to be true
    end

    it "detects NPC fight from participation" do
      arena_match.update!(metadata: {})
      processor = Arena::CombatProcessor.new(arena_match)
      expect(processor.npc_fight?).to be true
    end
  end

  # ===========================================================================
  # NPC Combat AI
  # ===========================================================================

  describe "Arena::NpcCombatAi" do
    let!(:arena_match) do
      create(:arena_match, :live,
        arena_room: arena_room,
        arena_season: arena_season,
        metadata: {"is_npc_fight" => true, "combat_log" => []})
    end

    let!(:player_participation) do
      create(:arena_participation,
        arena_match: arena_match,
        character: character,
        user: user,
        team: "a")
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: arena_match,
        npc_template: arena_bot,
        team: "b",
        metadata: {"current_hp" => 60, "max_hp" => 60})
    end

    describe "#decide_action" do
      it "returns a valid action decision" do
        ai = Arena::NpcCombatAi.new(
          npc_template: arena_bot,
          match: arena_match,
          rng: Random.new(1)
        )

        decision = ai.decide_action

        expect(decision.action_type).to be_in([:attack, :defend])
      end

      it "uses deterministic RNG for reproducible decisions" do
        ai1 = Arena::NpcCombatAi.new(
          npc_template: arena_bot,
          match: arena_match,
          rng: Random.new(12345)
        )

        ai2 = Arena::NpcCombatAi.new(
          npc_template: arena_bot,
          match: arena_match,
          rng: Random.new(12345)
        )

        decision1 = ai1.decide_action
        decision2 = ai2.decide_action

        expect(decision1.action_type).to eq(decision2.action_type)
      end

      context "when NPC HP is low" do
        before do
          npc_participation.update!(metadata: {"current_hp" => 10, "max_hp" => 60})
        end

        it "defensive AI may defend when HP is low" do
          arena_bot.update!(metadata: arena_bot.metadata.merge("ai_behavior" => "defensive"))

          defend_count = 0
          10.times do |i|
            ai = Arena::NpcCombatAi.new(
              npc_template: arena_bot.reload,
              match: arena_match,
              rng: Random.new(i)
            )
            defend_count += 1 if ai.decide_action.action_type == :defend
          end

          expect(defend_count).to be >= 1
        end
      end
    end

    describe "#stats" do
      it "returns NPC combat stats" do
        ai = Arena::NpcCombatAi.new(
          npc_template: arena_bot,
          match: arena_match,
          rng: Random.new(1)
        )

        stats = ai.stats

        expect(stats).to be_a(Hash)
        expect(stats[:attack]).to be_present
        expect(stats[:defense]).to be_present
      end
    end
  end

  # ===========================================================================
  # Authentication
  # ===========================================================================

  describe "authentication requirements" do
    before { sign_out :user }

    it "requires authentication to accept NPC application" do
      post accept_arena_application_path(npc_application)

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
