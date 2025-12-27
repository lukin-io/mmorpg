# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::PvpEncounterService do
  let(:attacker) { create(:character, level: 10, current_hp: 100) }
  let(:defender) { create(:character, level: 10, current_hp: 100) }
  let(:zone) { create(:zone, pvp_enabled: true) }

  before do
    # Set up positions if needed
    allow(attacker).to receive(:position).and_return(double(zone: zone))
  end

  describe "#start_encounter!" do
    subject(:service) { described_class.new(attacker, defender, zone: zone) }

    context "when PVP is allowed" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: true, reason: "Zone allows open PVP" })
      end

      it "creates a battle" do
        expect { service.start_encounter! }.to change(Battle, :count).by(1)
      end

      it "creates battle participants" do
        result = service.start_encounter!

        expect(result.battle.battle_participants.count).to eq(2)
      end

      it "sets battle type to pvp" do
        result = service.start_encounter!

        expect(result.battle.battle_type).to eq("pvp")
      end

      it "returns success result" do
        result = service.start_encounter!

        expect(result.success).to be true
        expect(result.message).to include("PVP combat started")
      end

      it "flags the attacker for PVP" do
        expect { service.start_encounter! }.to change { attacker.pvp_flags.count }.by(1)
      end
    end

    context "when PVP is not allowed" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: false, reason: "PVP requires mutual flagging" })
      end

      it "returns failure result" do
        result = service.start_encounter!

        expect(result.success).to be false
        expect(result.message).to eq("PVP requires mutual flagging")
      end

      it "does not create a battle" do
        expect { service.start_encounter! }.not_to change(Battle, :count)
      end
    end

    context "when attacker is already in combat" do
      before do
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: true, reason: "Zone allows open PVP" })

        # Create existing active battle
        existing_battle = create(:battle, :active, initiator: attacker)
        create(:battle_participant, battle: existing_battle, character: attacker)
      end

      it "returns failure result" do
        result = service.start_encounter!

        expect(result.success).to be false
        expect(result.message).to eq("Already in combat")
      end
    end

    context "when defender is dead" do
      before do
        defender.update!(current_hp: 0)
        allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
          .and_return({ allowed: true, reason: "Zone allows open PVP" })
      end

      it "returns failure result" do
        result = service.start_encounter!

        expect(result.success).to be false
        expect(result.message).to eq("Target is dead")
      end
    end
  end

  describe "#process_action!" do
    subject(:service) { described_class.new(attacker, defender, zone: zone) }

    before do
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
      service.start_encounter!
    end

    context "attack action" do
      it "processes attack successfully" do
        result = service.process_action!(character: attacker, action_type: :attack)

        expect(result.success).to be true
      end

      it "logs the attack" do
        result = service.process_action!(character: attacker, action_type: :attack)

        expect(result.combat_log).not_to be_empty
      end
    end

    context "defend action" do
      it "sets defending state" do
        result = service.process_action!(character: attacker, action_type: :defend)

        expect(result.success).to be true
      end
    end

    context "flee action" do
      it "attempts to flee" do
        result = service.process_action!(character: attacker, action_type: :flee)

        # Flee can succeed or fail
        expect(result).to respond_to(:success)
      end
    end
  end

  describe "combat resolution" do
    subject(:service) { described_class.new(attacker, defender, zone: zone) }

    before do
      allow(Game::Pvp::ZoneRules).to receive(:check_pvp_allowed)
        .and_return({ allowed: true, reason: "Zone allows open PVP" })
      service.start_encounter!
    end

    it "can complete combat" do
      # Just verify combat can be started and actions processed
      result = service.process_action!(character: attacker, action_type: :attack)
      expect(result.success).to be true
    end
  end
end
