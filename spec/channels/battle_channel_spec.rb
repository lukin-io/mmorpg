# frozen_string_literal: true

require "rails_helper"

RSpec.describe BattleChannel, type: :channel do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:battle) { create(:battle, status: :active, initiator: character) }
  let!(:participant) do
    create(:battle_participant,
      battle: battle,
      character: character,
      team: "player",
      is_alive: true,
      current_hp: 100,
      max_hp: 100)
  end

  describe "#subscribed" do
    context "with valid battle and participant" do
      it "confirms subscription" do
        stub_connection current_user: user
        subscribe(battle_id: battle.id)

        expect(subscription).to be_confirmed
      end

      it "streams from battle channel" do
        stub_connection current_user: user
        subscribe(battle_id: battle.id)

        expect(subscription).to have_stream_from("battle:#{battle.id}")
      end
    end

    context "with non-participant user" do
      let(:other_user) { create(:user) }
      let!(:other_character) { create(:character, user: other_user) }

      it "rejects subscription" do
        stub_connection current_user: other_user
        subscribe(battle_id: battle.id)

        expect(subscription).to be_rejected
      end
    end

    context "with invalid battle id" do
      it "rejects subscription for non-existent battle" do
        stub_connection current_user: user
        subscribe(battle_id: 999999)

        expect(subscription).to be_rejected
      end

      it "rejects subscription for nil battle id" do
        stub_connection current_user: user
        subscribe(battle_id: nil)

        expect(subscription).to be_rejected
      end
    end

    context "without authentication" do
      it "rejects subscription when user is nil" do
        stub_connection current_user: nil
        subscribe(battle_id: battle.id)

        expect(subscription).to be_rejected
      end
    end
  end

  describe "#unsubscribed" do
    it "stops all streams" do
      stub_connection current_user: user
      subscribe(battle_id: battle.id)
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end

  describe "#request_state" do
    before do
      stub_connection current_user: user
      subscribe(battle_id: battle.id)
    end

    it "performs request_state action without error" do
      expect { perform(:request_state) }.not_to raise_error
    end

    it "includes battle data in transmission" do
      perform(:request_state)

      # Check that something was transmitted
      expect(transmissions.size).to eq(1)
      transmission = transmissions.first

      expect(transmission["type"]).to eq("battle_state")
      expect(transmission["battle_id"]).to eq(battle.id)
      expect(transmission["status"]).to eq("active")
      expect(transmission["turn_number"]).to eq(battle.turn_number)
    end

    it "includes participants in transmission" do
      perform(:request_state)
      transmission = transmissions.first

      expect(transmission["participants"]).to be_an(Array)
      participant_data = transmission["participants"].find { |p| p["id"] == participant.id }

      expect(participant_data["name"]).to eq(character.name)
      expect(participant_data["team"]).to eq("player")
      expect(participant_data["current_hp"]).to eq(100)
      expect(participant_data["max_hp"]).to eq(100)
    end

    context "with multiple participants" do
      let(:npc_template) { create(:npc_template, name: "Goblin") }
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

      it "includes all participants in transmission" do
        perform(:request_state)
        transmission = transmissions.first

        expect(transmission["participants"].size).to eq(2)

        player_data = transmission["participants"].find { |p| p["id"] == participant.id }
        enemy_data = transmission["participants"].find { |p| p["id"] == enemy_participant.id }

        expect(player_data).to be_present
        expect(enemy_data).to be_present
        expect(enemy_data["name"]).to eq("Goblin")
      end
    end
  end

  # Note: Private method #user_in_battle? is tested indirectly through
  # the subscription tests above. Direct unit testing of private methods
  # is not possible with RSpec channel testing because the channel doesn't
  # have access to current_user outside of a subscription context.

  describe "broadcast integration" do
    it "can receive broadcasts on the battle channel" do
      stub_connection current_user: user
      subscribe(battle_id: battle.id)

      expect(subscription).to have_stream_from("battle:#{battle.id}")
    end
  end
end
