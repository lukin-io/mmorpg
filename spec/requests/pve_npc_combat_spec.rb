# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# PvE NPC Combat Request Specs
# =============================================================================
# Comprehensive tests for open world PvE (Player vs NPC) combat mechanics.
# Tests cover: starting encounters, combat actions, victory/defeat, rewards,
# and Turbo Stream integration.
#
# Related docs:
#   - doc/flow/16_combat_system.md
#   - doc/flow/4_world_npc_systems.md
#   - doc/flow/22_unified_npc_architecture.md
# =============================================================================

RSpec.describe "PvE NPC Combat", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:zone) { create(:zone, name: "Whispering Woods", biome: "forest") }
  let(:character) do
    create(:character, :with_position,
      user: user,
      name: "HeroWarrior",
      level: 5,
      current_hp: 100,
      max_hp: 100,
      experience: 100)
  end

  let(:hostile_npc) do
    create(:npc_template,
      npc_key: "forest_goblin",
      name: "Forest Goblin",
      role: "hostile",
      level: 3,
      dialogue: "*snarls aggressively*",
      metadata: {
        "health" => 40,
        "base_damage" => 8,
        "xp_reward" => 25,
        "gold_reward" => 10,
        "stats" => {"attack" => 10, "defense" => 5, "agility" => 6, "hp" => 40}
      })
  end

  before do
    sign_in user, scope: :user
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character)
  end

  # ===========================================================================
  # Starting PvE Combat Encounters
  # ===========================================================================

  describe "POST /combat/start" do
    context "success - starting combat with hostile NPC" do
      it "creates a new battle" do
        expect {
          post start_combat_path, params: {npc_template_id: hostile_npc.id}
        }.to change(Battle, :count).by(1)
      end

      it "creates battle participants for player and NPC" do
        expect {
          post start_combat_path, params: {npc_template_id: hostile_npc.id}
        }.to change(BattleParticipant, :count).by(2)
      end

      it "sets battle type to PvE" do
        post start_combat_path, params: {npc_template_id: hostile_npc.id}

        battle = Battle.last
        expect(battle.battle_type).to eq("pve")
      end

      it "sets NPC HP from unified architecture" do
        post start_combat_path, params: {npc_template_id: hostile_npc.id}

        battle = Battle.last
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        expect(npc_participant.max_hp).to eq(40)
        expect(npc_participant.current_hp).to eq(40)
      end

      it "redirects to combat page" do
        post start_combat_path, params: {npc_template_id: hostile_npc.id}

        expect(response).to redirect_to(combat_path)
      end

      context "with JSON format" do
        it "returns success JSON" do
          post start_combat_path, params: {npc_template_id: hostile_npc.id}, as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["battle_id"]).to be_present
        end
      end

      context "with Turbo Stream format" do
        let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

        it "redirects with see_other status" do
          post start_combat_path,
            params: {npc_template_id: hostile_npc.id},
            headers: turbo_headers

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(combat_path)
        end
      end
    end

    context "failure cases" do
      it "rejects non-hostile NPC" do
        friendly_npc = create(:npc_template, role: "vendor", name: "Friendly Vendor")

        post start_combat_path, params: {npc_template_id: friendly_npc.id}, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("not hostile")
      end

      it "rejects non-existent NPC" do
        post start_combat_path, params: {npc_template_id: 999999}, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("NPC not found")
      end

      it "handles already in combat gracefully" do
        existing_battle = create(:battle, initiator: character, status: :active)
        create(:battle_participant, battle: existing_battle, character: character, team: "player")
        create(:battle_participant, battle: existing_battle, npc_template: hostile_npc, team: "enemy")

        post start_combat_path, params: {npc_template_id: hostile_npc.id}

        expect(response).to redirect_to(combat_path)
      end
    end
  end

  # ===========================================================================
  # Combat Actions
  # ===========================================================================

  describe "POST /combat/action" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        battle_type: :pve,
        turn_number: 1)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 100,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 40,
        max_hp: 40)
    end

    describe "attack action" do
      it "processes attack and damages NPC" do
        post action_combat_path, params: {action_type: "attack"}, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["combat_log"]).to be_present
      end

      it "reduces NPC HP" do
        initial_hp = enemy_participant.current_hp

        post action_combat_path, params: {action_type: "attack"}, as: :json

        enemy_participant.reload
        expect(enemy_participant.current_hp).to be < initial_hp
      end

      it "returns combat log with all actions" do
        post action_combat_path, params: {action_type: "attack"}, as: :json

        json = JSON.parse(response.body)
        expect(json["combat_log"]).to be_an(Array)
        expect(json["combat_log"].length).to be >= 1
      end

      context "with Turbo Stream" do
        let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

        it "returns turbo stream content" do
          post action_combat_path, params: {action_type: "attack"}, headers: turbo_headers

          expect(response.content_type).to include("turbo-stream")
        end

        it "updates HP bars" do
          post action_combat_path, params: {action_type: "attack"}, headers: turbo_headers

          expect(response.body).to include("participant-#{player_participant.id}")
          expect(response.body).to include("participant-#{enemy_participant.id}")
        end
      end
    end

    describe "defend action" do
      it "processes defend action" do
        post action_combat_path, params: {action_type: "defend"}, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    describe "turn-based combat" do
      let(:attacks) { [{"body_part" => "head", "action_key" => "simple", "slot_index" => 0}] }
      let(:blocks) { [{"body_part" => "torso", "action_key" => "basic_block", "slot_index" => 0}] }

      it "processes full turn with attacks and blocks" do
        post action_combat_path,
          params: {
            action_type: "turn",
            attacks: attacks.to_json,
            blocks: blocks.to_json,
            skills: [].to_json
          },
          as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["combat_log"]).to be_an(Array)
      end

      it "creates combat log entries" do
        expect {
          post action_combat_path,
            params: {
              action_type: "turn",
              attacks: attacks.to_json,
              blocks: blocks.to_json,
              skills: [].to_json
            },
            as: :json
        }.to change(CombatLogEntry, :count).by_at_least(1)
      end
    end
  end

  # ===========================================================================
  # Flee Action
  # ===========================================================================

  describe "POST /combat/flee" do
    let!(:battle) do
      create(:battle, status: :active, initiator: character)
    end

    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true,
        current_hp: 50,
        max_hp: 100)
    end

    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: hostile_npc,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 40,
        max_hp: 40)
    end

    it "attempts to flee combat" do
      post flee_combat_path, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to be_present
    end
  end

  # ===========================================================================
  # GET /combat (View Combat)
  # ===========================================================================

  describe "GET /combat" do
    context "with active battle" do
      let!(:battle) do
        create(:battle, status: :active, initiator: character, battle_type: :pve)
      end

      let!(:player_participant) do
        create(:battle_participant,
          battle: battle,
          character: character,
          team: "player",
          is_alive: true,
          current_hp: 80,
          max_hp: 100)
      end

      let!(:enemy_participant) do
        create(:battle_participant,
          battle: battle,
          npc_template: hostile_npc,
          character: nil,
          team: "enemy",
          is_alive: true,
          current_hp: 30,
          max_hp: 40)
      end

      it "renders combat interface" do
        get combat_path

        expect(response).to have_http_status(:ok)
      end

      it "displays NPC opponent name" do
        get combat_path

        expect(response.body).to include("Forest Goblin")
      end
    end

    context "without active battle" do
      it "redirects to world" do
        get combat_path

        expect(response).to redirect_to(world_path)
      end
    end
  end

  # ===========================================================================
  # GET /combat/skills
  # ===========================================================================

  describe "GET /combat/skills" do
    let!(:battle) do
      create(:battle, status: :active, initiator: character)
    end

    let!(:participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true)
    end

    it "returns skills list" do
      get skills_combat_path, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["skills"]).to be_an(Array)
    end

    context "with character abilities" do
      let!(:ability) do
        create(:ability,
          character_class: character.character_class,
          name: "Power Strike",
          kind: "active")
      end

      it "includes class abilities" do
        get skills_combat_path, as: :json

        json = JSON.parse(response.body)
        skill_names = json["skills"].map { |s| s["name"] }
        expect(skill_names).to include("Power Strike")
      end
    end
  end

  # ===========================================================================
  # NPC Stat Integration (Unified Architecture)
  # ===========================================================================

  describe "unified NPC architecture integration" do
    context "NPC with level-based formulas" do
      let(:formula_npc) do
        create(:npc_template,
          role: "hostile",
          name: "Formula Test NPC",
          level: 10,
          metadata: {})
      end

      it "calculates stats from level when no metadata override" do
        post start_combat_path, params: {npc_template_id: formula_npc.id}

        battle = Battle.last
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        expected_hp = formula_npc.combat_stats[:hp]
        expect(npc_participant.max_hp).to eq(expected_hp)
      end
    end

    context "NPC with metadata stat overrides" do
      let(:custom_npc) do
        create(:npc_template,
          role: "hostile",
          name: "Custom Stats NPC",
          level: 5,
          metadata: {
            "stats" => {"attack" => 50, "defense" => 30, "hp" => 200}
          })
      end

      it "uses metadata stats over formula" do
        post start_combat_path, params: {npc_template_id: custom_npc.id}

        battle = Battle.last
        npc_participant = battle.battle_participants.find_by(team: "enemy")

        expect(npc_participant.max_hp).to eq(200)
      end
    end
  end

  # ===========================================================================
  # Authentication
  # ===========================================================================

  describe "authentication" do
    before { sign_out :user }

    it "requires authentication for combat view" do
      get combat_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires authentication to start combat" do
      post start_combat_path, params: {npc_template_id: hostile_npc.id}

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
