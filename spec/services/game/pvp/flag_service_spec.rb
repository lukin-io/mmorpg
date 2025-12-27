# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Pvp::FlagService do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character) }
  let(:service) { described_class.new(character) }

  # =============================================================================
  # SUCCESS CASES
  # =============================================================================
  describe "#enable_pvp!" do
    it "creates a voluntary PVP flag" do
      result = service.enable_pvp!

      expect(result.success).to be true
      expect(result.flag).to be_present
      expect(result.flag.voluntary?).to be true
    end

    it "creates a flag with no expiry" do
      result = service.enable_pvp!

      expect(result.flag.expires_at).to be_nil
    end

    it "returns success message" do
      result = service.enable_pvp!

      expect(result.message).to include("PVP mode enabled")
    end
  end

  describe "#disable_pvp!" do
    before { create(:pvp_flag, :voluntary, character: character) }

    it "removes the voluntary flag" do
      expect {
        service.disable_pvp!
      }.to change { character.pvp_flags.voluntary.count }.by(-1)
    end

    it "returns success" do
      result = service.disable_pvp!

      expect(result.success).to be true
      expect(result.message).to include("disabled")
    end
  end

  describe "#auto_flag!" do
    it "creates a hostile_action flag" do
      result = service.auto_flag!(:hostile_action)

      expect(result.success).to be true
      expect(result.flag.hostile_action?).to be true
    end

    it "creates a zone_flag" do
      result = service.auto_flag!(:zone_flag)

      expect(result.success).to be true
      expect(result.flag.zone_flag?).to be true
    end

    it "sets expiry for hostile_action" do
      result = service.auto_flag!(:hostile_action)

      expect(result.flag.expires_at).to be_present
      expect(result.flag.expires_at).to be > Time.current
    end

    it "extends existing flag of same type" do
      existing = create(:pvp_flag, :hostile_action, character: character, expires_at: 1.minute.from_now)

      result = service.auto_flag!(:hostile_action)

      expect(result.success).to be true
      expect(character.pvp_flags.hostile_action.count).to eq(1)
      expect(existing.reload.expires_at).to be > 1.minute.from_now
    end
  end

  describe "#flag_for_hostile_action!" do
    let(:defender) { create(:character) }

    it "creates a hostile_action flag" do
      result = service.flag_for_hostile_action!(defender)

      expect(result.success).to be true
      expect(result.flag.hostile_action?).to be true
    end

    it "includes defender ID in source" do
      result = service.flag_for_hostile_action!(defender)

      expect(result.flag.source).to include(defender.id.to_s)
    end
  end

  describe "#flag_for_zone!" do
    let(:zone) { create(:zone, pvp_enabled: true) }

    it "creates a zone_flag" do
      result = service.flag_for_zone!(zone)

      expect(result.success).to be true
      expect(result.flag.zone_flag?).to be true
    end

    it "includes zone ID in source" do
      result = service.flag_for_zone!(zone)

      expect(result.flag.source).to include(zone.id.to_s)
    end
  end

  describe "#unflag_for_zone!" do
    before { create(:pvp_flag, :zone_flag, character: character) }

    it "sets expiry on zone flag" do
      result = service.unflag_for_zone!

      expect(result.success).to be true
      expect(result.flag.expires_at).to be_present
    end
  end

  describe "#pvp_flagged?" do
    context "when character has active flags" do
      before { create(:pvp_flag, :voluntary, character: character) }

      it "returns true" do
        expect(service.pvp_flagged?).to be true
      end
    end

    context "when character has no flags" do
      it "returns false" do
        expect(service.pvp_flagged?).to be false
      end
    end

    context "when all flags are expired" do
      before { create(:pvp_flag, :expired, character: character) }

      it "returns false" do
        expect(service.pvp_flagged?).to be false
      end
    end
  end

  describe "#clear_expired!" do
    before do
      create(:pvp_flag, :expired, character: character)
      create(:pvp_flag, :voluntary, character: character)
    end

    it "removes only expired flags" do
      expect {
        service.clear_expired!
      }.to change { character.pvp_flags.count }.by(-1)

      expect(character.pvp_flags.first.voluntary?).to be true
    end
  end

  # =============================================================================
  # FAILURE CASES
  # =============================================================================
  describe "#enable_pvp! - failure cases" do
    context "when already flagged" do
      before { create(:pvp_flag, :voluntary, character: character) }

      it "returns failure" do
        result = service.enable_pvp!

        expect(result.success).to be false
        expect(result.message).to include("Already flagged")
      end

      it "does not create duplicate flag" do
        expect {
          service.enable_pvp!
        }.not_to change { character.pvp_flags.count }
      end
    end
  end

  describe "#disable_pvp! - failure cases" do
    context "when no voluntary flag exists" do
      it "returns failure" do
        result = service.disable_pvp!

        expect(result.success).to be false
        expect(result.message).to include("No active PVP flag")
      end
    end

    context "when only hostile_action flag exists" do
      before { create(:pvp_flag, :hostile_action, character: character) }

      it "returns failure" do
        result = service.disable_pvp!

        expect(result.success).to be false
      end
    end
  end

  # =============================================================================
  # NULL/EDGE CASES
  # =============================================================================
  describe "edge cases" do
    context "when character has multiple flag types" do
      before do
        create(:pvp_flag, :voluntary, character: character)
        create(:pvp_flag, :hostile_action, character: character)
      end

      it "reports as flagged" do
        expect(service.pvp_flagged?).to be true
      end

      it "returns all active flags" do
        expect(service.active_flags.count).to eq(2)
      end
    end

    context "when flag expires during check" do
      it "handles expiry correctly" do
        create(:pvp_flag, :expiring_soon, character: character, expires_at: 1.second.from_now)

        expect(service.pvp_flagged?).to be true

        # Wait for expiry
        travel_to 2.seconds.from_now do
          expect(service.pvp_flagged?).to be false
        end
      end
    end
  end
end
