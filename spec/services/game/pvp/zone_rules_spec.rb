# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Pvp::ZoneRules do
  let(:attacker) { create(:character, faction_alignment: "alliance") }
  let(:defender) { create(:character, faction_alignment: "rebellion") }

  describe ".pvp_allowed?" do
    context "in a safe zone (city biome)" do
      let(:zone) { instance_double(Zone, biome: "city", pvp_enabled?: false, pvp_mode: nil) }

      it "returns false" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be false
      end
    end

    context "when zone has pvp_enabled with open mode" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "open") }

      it "returns true" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be true
      end
    end

    context "when zone has pvp_enabled with arena mode" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "arena") }

      it "returns true" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be true
      end
    end

    context "when zone has pvp_enabled with battleground mode" do
      let(:zone) { instance_double(Zone, biome: "plains", pvp_enabled?: true, pvp_mode: "battleground") }

      it "returns true" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be true
      end
    end

    context "when both players are flagged" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: false, pvp_mode: nil) }

      before do
        create(:pvp_flag, :voluntary, character: attacker)
        create(:pvp_flag, :voluntary, character: defender)
      end

      it "returns true" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be true
      end
    end

    context "when only attacker is flagged" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: false, pvp_mode: nil) }

      before do
        create(:pvp_flag, :voluntary, character: attacker)
      end

      it "returns false" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: defender)).to be false
      end
    end

    context "when attacking self" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "open") }

      it "returns false" do
        expect(described_class.pvp_allowed?(zone, attacker: attacker, defender: attacker)).to be false
      end
    end

    context "when zone is nil" do
      context "and both players are flagged" do
        before do
          create(:pvp_flag, :voluntary, character: attacker)
          create(:pvp_flag, :voluntary, character: defender)
        end

        it "returns true" do
          expect(described_class.pvp_allowed?(nil, attacker: attacker, defender: defender)).to be true
        end
      end

      context "and only one player is flagged" do
        before do
          create(:pvp_flag, :voluntary, character: attacker)
        end

        it "returns false" do
          expect(described_class.pvp_allowed?(nil, attacker: attacker, defender: defender)).to be false
        end
      end
    end

    context "in faction warfare mode" do
      let(:zone) { instance_double(Zone, biome: "plains", pvp_enabled?: true, pvp_mode: "faction_war") }
      let(:alliance_char) { create(:character, faction_alignment: "alliance") }
      let(:rebellion_char) { create(:character, faction_alignment: "rebellion") }
      let(:neutral_char) { create(:character, faction_alignment: "neutral") }

      it "allows opposing factions (alliance vs rebellion) to fight" do
        expect(described_class.pvp_allowed?(zone, attacker: alliance_char, defender: rebellion_char)).to be true
      end

      it "allows opposing factions (rebellion vs alliance) to fight" do
        expect(described_class.pvp_allowed?(zone, attacker: rebellion_char, defender: alliance_char)).to be true
      end

      it "requires flagging for same faction (alliance vs alliance)" do
        another_alliance = create(:character, faction_alignment: "alliance")
        expect(described_class.pvp_allowed?(zone, attacker: alliance_char, defender: another_alliance)).to be false
      end

      it "requires flagging when neutral is involved" do
        # Neutral is not part of faction war
        expect(described_class.pvp_allowed?(zone, attacker: alliance_char, defender: neutral_char)).to be false
      end
    end
  end

  describe ".check_pvp_allowed" do
    context "in a safe zone (city biome)" do
      let(:zone) { instance_double(Zone, biome: "city", pvp_enabled?: false, pvp_mode: nil) }

      it "returns reason for rejection" do
        result = described_class.check_pvp_allowed(zone, attacker, defender)

        expect(result[:allowed]).to be false
        expect(result[:reason]).to include("safe zone")
      end
    end

    context "in a PVP-enabled zone" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "open") }

      it "returns reason for allowing" do
        result = described_class.check_pvp_allowed(zone, attacker, defender)

        expect(result[:allowed]).to be true
        expect(result[:reason]).to include("open PVP")
      end
    end

    context "when attacking self" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "open") }

      it "returns reason for rejection" do
        result = described_class.check_pvp_allowed(zone, attacker, attacker)

        expect(result[:allowed]).to be false
        expect(result[:reason]).to include("Cannot attack yourself")
      end
    end

    context "when flagged warfare in flagged mode" do
      let(:zone) { instance_double(Zone, biome: "forest", pvp_enabled?: true, pvp_mode: "flagged") }

      context "with both flagged" do
        before do
          create(:pvp_flag, :voluntary, character: attacker)
          create(:pvp_flag, :voluntary, character: defender)
        end

        it "allows combat" do
          result = described_class.check_pvp_allowed(zone, attacker, defender)

          expect(result[:allowed]).to be true
          expect(result[:reason]).to include("flagged for PVP")
        end
      end

      context "with neither flagged" do
        it "denies combat" do
          result = described_class.check_pvp_allowed(zone, attacker, defender)

          expect(result[:allowed]).to be false
          expect(result[:reason]).to include("mutual flagging")
        end
      end
    end
  end
end
