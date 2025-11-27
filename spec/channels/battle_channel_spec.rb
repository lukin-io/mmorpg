# frozen_string_literal: true

require "rails_helper"

# Skip if BattleChannel is not yet implemented
RSpec.describe "BattleChannel", type: :channel, skip: !defined?(BattleChannel) do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:battle) { create(:battle, status: :active) }
  let!(:participant) do
    create(:battle_participant, battle: battle, character: character, team: "alpha")
  end

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "with valid battle" do
      it "successfully subscribes" do
        subscribe(battle_id: battle.id)

        expect(subscription).to be_confirmed
      end

      it "streams from battle-specific channel" do
        subscribe(battle_id: battle.id)

        expect(subscription).to have_stream_from("battle_#{battle.id}")
      end
    end

    context "with non-participant" do
      let(:other_user) { create(:user) }

      before do
        stub_connection current_user: other_user
      end

      it "rejects subscription" do
        subscribe(battle_id: battle.id)

        expect(subscription).to be_rejected
      end
    end

    context "with invalid battle" do
      it "rejects subscription for non-existent battle" do
        subscribe(battle_id: 999999)

        expect(subscription).to be_rejected
      end
    end
  end

  describe "#unsubscribed" do
    it "cleans up on disconnect" do
      subscribe(battle_id: battle.id)
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
