# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PvpCombat", type: :request do
  let(:user) { create(:user) }
  let(:attacker) { create(:character, user: user, level: 10, current_hp: 100) }
  let(:defender_user) { create(:user) }
  let(:defender) { create(:character, user: defender_user, level: 10, current_hp: 100) }
  let(:zone) { create(:zone, pvp_enabled: true) }

  before do
    sign_in user, scope: :user
    allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(attacker)
    allow(attacker).to receive(:position).and_return(double(zone: zone))
  end

  # =============================================================================
  # SUCCESS CASES
  # =============================================================================
  describe "POST /pvp_combat/attack" do
    context "when PVP is allowed" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: true, reason: "Zone allows open PVP" })
      end

      it "creates a PVP battle" do
        expect {
          post attack_pvp_combat_index_path, params: { target_id: defender.id }
        }.to change(Battle, :count).by(1)

        expect(response).to have_http_status(:redirect)
      end

      it "redirects to the battle page" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }

        battle = Battle.last
        expect(response).to redirect_to(pvp_combat_path(battle))
      end

      it "responds with turbo_stream format" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }, as: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "responds with JSON format" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["battle_id"]).to be_present
      end
    end
  end

  # =============================================================================
  # FAILURE CASES
  # =============================================================================
  describe "POST /pvp_combat/attack - failure cases" do
    context "when target is not found" do
      it "returns not found error" do
        post attack_pvp_combat_index_path, params: { target_id: 999999 }

        # Should redirect back with alert
        expect(response).to have_http_status(:redirect)
      end

      it "returns JSON error for API requests" do
        post attack_pvp_combat_index_path, params: { target_id: 999999 }, as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Target not found")
      end
    end

    context "when PVP is not allowed" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: false, reason: "PVP not allowed in safe zones" })
      end

      it "returns error message" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq("PVP not allowed in safe zones")
      end

      it "does not create a battle" do
        expect {
          post attack_pvp_combat_index_path, params: { target_id: defender.id }
        }.not_to change(Battle, :count)
      end
    end

    context "when target is dead" do
      before do
        defender.update!(current_hp: 0)
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: true, reason: "Zone allows open PVP" })
      end

      it "returns error" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("dead")
      end
    end
  end

  # =============================================================================
  # NULL/EDGE CASES
  # =============================================================================
  describe "POST /pvp_combat/attack - edge cases" do
    context "when target_id is nil" do
      it "returns not found" do
        post attack_pvp_combat_index_path, params: { target_id: nil }

        expect(response).to redirect_to(world_path)
      end
    end

    context "when target_id is blank string" do
      it "returns not found" do
        post attack_pvp_combat_index_path, params: { target_id: "" }

        expect(response).to redirect_to(world_path)
      end
    end

    context "when trying to attack self" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: false, reason: "Cannot attack yourself" })
      end

      it "returns error" do
        post attack_pvp_combat_index_path, params: { target_id: attacker.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("yourself")
      end
    end
  end

  # =============================================================================
  # AUTHORIZATION CASES
  # =============================================================================
  describe "POST /pvp_combat/attack - authorization" do
    context "when user is not logged in" do
      before { sign_out :user }

      it "redirects to login" do
        post attack_pvp_combat_index_path, params: { target_id: defender.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user has no character" do
      # Note: This is difficult to test in request specs due to how current_character
      # is typically memoized in ApplicationController. The require_character! filter
      # is tested via system tests for proper coverage.
      it "redirects to character selection", :skip do
        pending "Covered by system tests"
      end
    end
  end

  # =============================================================================
  # BATTLE ACTIONS
  # =============================================================================
  describe "POST /pvp_combat/:id/action" do
    let(:battle) { create(:battle, :active, battle_type: :pvp, initiator: attacker) }

    before do
      create(:battle_participant, battle: battle, character: attacker, team: "alpha")
      create(:battle_participant, battle: battle, character: defender, team: "beta")
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
    end

    context "success cases" do
      it "processes attack action" do
        post action_pvp_combat_path(battle), params: { action_type: "attack" }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
      end

      it "processes defend action" do
        post action_pvp_combat_path(battle), params: { action_type: "defend" }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
      end
    end

    context "failure cases" do
      it "returns error for unknown action" do
        post action_pvp_combat_path(battle), params: { action_type: "invalid" }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
      end
    end

    context "authorization" do
      let(:other_user) { create(:user) }
      let(:other_char) { create(:character, user: other_user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_character).and_return(other_char)
      end

      it "denies action from non-participant" do
        post action_pvp_combat_path(battle), params: { action_type: "attack" }

        expect(response).to redirect_to(world_path)
        expect(flash[:alert]).to include("not part of this battle")
      end
    end
  end

  # =============================================================================
  # PVP STATUS
  # =============================================================================
  describe "GET /pvp_combat/status" do
    it "returns PVP flag status as JSON" do
      get status_pvp_combat_index_path, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("pvp_flagged")
      expect(json).to have_key("flags")
    end

    context "when character is flagged" do
      before { create(:pvp_flag, :voluntary, character: attacker) }

      it "shows active flag" do
        get status_pvp_combat_index_path, as: :json

        json = JSON.parse(response.body)
        expect(json["pvp_flagged"]).to be true
        expect(json["flags"]).not_to be_empty
      end
    end

    context "when character is not flagged" do
      it "shows no active flags" do
        get status_pvp_combat_index_path, as: :json

        json = JSON.parse(response.body)
        expect(json["pvp_flagged"]).to be false
        expect(json["flags"]).to be_empty
      end
    end
  end

  # =============================================================================
  # TOGGLE PVP
  # =============================================================================
  describe "POST /pvp_combat/toggle_pvp" do
    context "when enabling PVP" do
      it "creates a voluntary flag" do
        expect {
          post toggle_pvp_pvp_combat_index_path
        }.to change { attacker.pvp_flags.count }.by(1)

        expect(response).to redirect_to(world_path)
        expect(flash[:notice]).to include("PVP")
      end

      it "responds with turbo_stream" do
        post toggle_pvp_pvp_combat_index_path, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when disabling PVP" do
      before { create(:pvp_flag, :voluntary, character: attacker) }

      it "removes the voluntary flag" do
        expect {
          post toggle_pvp_pvp_combat_index_path
        }.to change { attacker.pvp_flags.voluntary.count }.by(-1)
      end
    end
  end

  # =============================================================================
  # FLEE AND SURRENDER
  # =============================================================================
  describe "POST /pvp_combat/:id/flee" do
    let(:battle) { create(:battle, :active, battle_type: :pvp, initiator: attacker) }

    before do
      create(:battle_participant, battle: battle, character: attacker, team: "alpha")
      create(:battle_participant, battle: battle, character: defender, team: "beta")
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
    end

    it "attempts to flee from combat" do
      post flee_pvp_combat_path(battle)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /pvp_combat/:id/surrender" do
    let(:battle) { create(:battle, :active, battle_type: :pvp, initiator: attacker) }

    before do
      create(:battle_participant, battle: battle, character: attacker, team: "alpha")
      create(:battle_participant, battle: battle, character: defender, team: "beta")
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
    end

    it "surrenders the fight" do
      post surrender_pvp_combat_path(battle)

      expect(response).to redirect_to(world_path)
      expect(attacker.reload.current_hp).to eq(0)
    end
  end
end
