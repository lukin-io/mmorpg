# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpcTemplate, type: :model do
  describe "scopes" do
    describe ".in_zone" do
      # This spec covers a bug where PostgreSQL's JSONB `?` operator conflicted
      # with Rails bind variable placeholders, causing:
      # ActiveRecord::PreparedStatementInvalid: wrong number of bind variables
      #
      # Fix: Use jsonb_exists() function instead of ? operator

      let!(:npc_single_zone) do
        create(:npc_template, name: "Forest Guardian", metadata: {"zone" => "dark_forest"})
      end

      let!(:npc_multi_zone) do
        create(:npc_template, name: "Wandering Merchant", metadata: {"zones" => ["dark_forest", "crystal_caves", "sunlit_plains"]})
      end

      let!(:npc_other_zone) do
        create(:npc_template, name: "Cave Troll", metadata: {"zone" => "crystal_caves"})
      end

      let!(:npc_no_zone) do
        create(:npc_template, name: "Random Monster", metadata: {})
      end

      it "finds NPCs with matching single zone in metadata" do
        result = described_class.in_zone("dark_forest")

        expect(result).to include(npc_single_zone)
        expect(result).not_to include(npc_other_zone)
        expect(result).not_to include(npc_no_zone)
      end

      it "finds NPCs with zone in zones array" do
        result = described_class.in_zone("dark_forest")

        expect(result).to include(npc_multi_zone)
      end

      it "finds NPCs from either single zone or zones array" do
        result = described_class.in_zone("dark_forest")

        expect(result).to contain_exactly(npc_single_zone, npc_multi_zone)
      end

      it "returns empty when no NPCs match the zone" do
        result = described_class.in_zone("nonexistent_zone")

        expect(result).to be_empty
      end

      it "finds NPCs in zones array by different zone name" do
        result = described_class.in_zone("crystal_caves")

        expect(result).to contain_exactly(npc_other_zone, npc_multi_zone)
      end

      it "handles nil zone gracefully" do
        # Should not raise an error
        expect { described_class.in_zone(nil).to_a }.not_to raise_error
      end

      it "handles empty string zone" do
        result = described_class.in_zone("")

        expect(result).to be_empty
      end

      it "is chainable with other scopes" do
        result = described_class.in_zone("dark_forest").where(role: "monster")

        expect(result).to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe "validations" do
    it "requires a name" do
      npc = build(:npc_template, name: nil)

      expect(npc).not_to be_valid
      expect(npc.errors[:name]).to be_present
    end
  end

  describe "metadata JSONB storage" do
    it "stores zone as string" do
      npc = create(:npc_template, metadata: {"zone" => "test_zone"})

      expect(npc.reload.metadata["zone"]).to eq("test_zone")
    end

    it "stores zones as array" do
      zones = ["zone_a", "zone_b", "zone_c"]
      npc = create(:npc_template, metadata: {"zones" => zones})

      expect(npc.reload.metadata["zones"]).to eq(zones)
    end
  end
end
