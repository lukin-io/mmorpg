# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Combat", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }

  before { sign_in user }

  describe "GET /combat" do
    context "without active battle" do
      it "redirects when no battle" do
        get combat_path

        # Should redirect to world or show empty state
        expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      end
    end
  end

  describe "POST /combat/action" do
    let!(:battle) do
      create(:battle,
        status: :active,
        initiator: character,
        combat_mode: "simultaneous",
        action_points_per_turn: 80)
    end
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "alpha",
        is_alive: true,
        current_hp: 100,
        max_hp: 100,
        current_mp: 50,
        max_mp: 50)
    end
    let!(:enemy_participant) do
      create(:battle_participant,
        battle: battle,
        character: nil,
        participant_type: "npc",
        team: "beta",
        is_alive: true,
        current_hp: 100,
        max_hp: 100)
    end

    context "with basic attack action" do
      let(:params) do
        {action_type: "attack", target_body_part: "head"}
      end

      it "processes the action" do
        post combat_action_path, params: params

        # Should respond with success or redirect
        expect(response).to have_http_status(:ok).or have_http_status(:redirect)
      end
    end
  end

  describe "POST /combat/flee" do
    let!(:battle) do
      create(:battle, status: :active, initiator: character)
    end
    let!(:participant) do
      create(:battle_participant,
        battle: battle,
        character: character,
        team: "alpha",
        is_alive: true)
    end

    it "attempts to flee from combat" do
      post combat_flee_path

      expect(response).to have_http_status(:ok).or have_http_status(:redirect)
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
        team: "alpha",
        is_alive: true)
    end

    it "returns skills data" do
      get combat_skills_path, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
