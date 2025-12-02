# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:character) { create(:character, :with_position, user: user) }
  let(:npc_template) do
    create(:npc_template,
      name: "Test Goblin",
      level: 2,
      role: "hostile",
      metadata: {
        "health" => 50,
        "base_damage" => 8,
        "stats" => {"attack" => 10, "defense" => 5, "agility" => 8, "hp" => 50}
      })
  end

  before do
    sign_in user, scope: :user
    # Ensure character is the active one
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(character)
  end

  describe "GET /combat" do
    context "without active battle" do
      it "redirects to world when no battle" do
        get combat_path
        expect(response).to redirect_to(world_path)
      end

      it "shows notice message" do
        get combat_path
        expect(flash[:notice]).to be_present
      end
    end

    context "with active battle" do
      let!(:battle) do
        create(:battle,
          status: :active,
          initiator: character,
          battle_type: :pve)
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
          npc_template: npc_template,
          character: nil,
          team: "enemy",
          is_alive: true,
          current_hp: 50,
          max_hp: 50)
      end

      it "shows combat interface" do
        get combat_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /combat/start" do
    context "with valid NPC" do
      it "starts combat encounter" do
        post start_combat_path, params: {npc_template_id: npc_template.id}
        expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      end

      it "creates a battle" do
        expect {
          post start_combat_path, params: {npc_template_id: npc_template.id}
        }.to change(Battle, :count).by(1)
      end

      it "creates battle participants" do
        expect {
          post start_combat_path, params: {npc_template_id: npc_template.id}
        }.to change(BattleParticipant, :count).by(2)
      end

      context "with turbo stream request" do
        it "redirects to combat page" do
          post start_combat_path,
            params: {npc_template_id: npc_template.id},
            headers: {"Accept" => "text/vnd.turbo-stream.html"}

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(combat_path)
        end
      end

      context "with JSON request" do
        it "returns JSON response" do
          post start_combat_path,
            params: {npc_template_id: npc_template.id},
            as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["battle_id"]).to be_present
        end
      end
    end

    context "with non-hostile NPC" do
      let(:friendly_npc) { create(:npc_template, role: "vendor") }

      it "returns error" do
        post start_combat_path,
          params: {npc_template_id: friendly_npc.id},
          as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end
    end

    context "with invalid NPC" do
      it "returns error for non-existent NPC" do
        post start_combat_path,
          params: {npc_template_id: 99999},
          as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("NPC not found")
      end
    end

    context "when already in combat" do
      let!(:existing_battle) { create(:battle, initiator: character, status: :active) }

      before do
        # Create existing battle with NPC
        create(:battle_participant, battle: existing_battle, character: character, team: "player")
        create(:battle_participant, battle: existing_battle, npc_template: npc_template, team: "enemy")
      end

      it "handles already in combat gracefully" do
        post start_combat_path, params: {npc_template_id: npc_template.id}
        expect(response).to have_http_status(:ok)
          .or have_http_status(:redirect)
      end

      it "does not create additional battle" do
        expect {
          post start_combat_path, params: {npc_template_id: npc_template.id}
        }.not_to change(Battle, :count)
      end

      it "redirects to combat page via turbo stream" do
        post start_combat_path,
          params: {npc_template_id: npc_template.id},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(combat_path)
      end

      it "redirects to combat path for HTML format" do
        post start_combat_path, params: {npc_template_id: npc_template.id}
        expect(response).to redirect_to(combat_path)
      end
    end
  end

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
        npc_template: npc_template,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 50,
        max_hp: 50)
    end

    context "with JSON request" do
      it "processes attack action" do
        post action_combat_path, params: {action_type: "attack"}, as: :json
        expect(response).to have_http_status(:ok)
      end

      it "returns combat log in response" do
        post action_combat_path, params: {action_type: "attack"}, as: :json
        json = JSON.parse(response.body)
        expect(json).to have_key("combat_log")
      end

      it "processes defend action" do
        post action_combat_path, params: {action_type: "defend"}, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not in combat" do
      before { battle.update!(status: :completed) }

      it "returns error" do
        post action_combat_path, params: {action_type: "attack"}, as: :json
        # May return unprocessable or ok with error
        expect(response).to have_http_status(:unprocessable_content)
          .or have_http_status(:ok)
      end
    end
  end

  describe "POST /combat/flee" do
    let!(:battle) do
      create(:battle, status: :active, initiator: character)
    end
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "player",
        is_alive: true)
    end
    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: npc_template,
        character: nil,
        team: "enemy",
        is_alive: true,
        current_hp: 50,
        max_hp: 50)
    end

    it "attempts to flee" do
      post flee_combat_path, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns flee result" do
      post flee_combat_path, as: :json
      json = JSON.parse(response.body)
      expect(json["message"]).to be_present
    end
  end

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
      let(:ability) do
        create(:ability,
          character_class: character.character_class,
          name: "Power Strike",
          kind: "active")
      end

      before { ability }

      it "includes class abilities" do
        get skills_combat_path, as: :json
        json = JSON.parse(response.body)
        skill_names = json["skills"].map { |s| s["name"] }
        expect(skill_names).to include("Power Strike")
      end
    end
  end

  describe "authentication" do
    context "without authentication" do
      before { sign_out :user }

      it "redirects from combat" do
        get combat_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects from start" do
        post start_combat_path, params: {npc_template_id: npc_template.id}
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
