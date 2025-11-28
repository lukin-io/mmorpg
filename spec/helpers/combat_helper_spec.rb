# frozen_string_literal: true

require "rails_helper"

RSpec.describe CombatHelper, type: :helper do
  describe "#format_vital" do
    it "formats HP correctly" do
      expect(helper.format_vital(75, 100)).to eq("75/100")
    end

    it "handles zero HP" do
      expect(helper.format_vital(0, 100)).to eq("0/100")
    end

    it "handles max HP" do
      expect(helper.format_vital(100, 100)).to eq("100/100")
    end
  end

  describe "#vital_bar_width" do
    it "calculates percentage correctly" do
      expect(helper.vital_bar_width(50, 100)).to eq(50)
    end

    it "handles zero max" do
      expect(helper.vital_bar_width(50, 0)).to eq(0)
    end

    it "clamps to 100%" do
      expect(helper.vital_bar_width(150, 100)).to eq(100)
    end
  end

  describe "#combat_action_icon" do
    it "returns sword icon for attack" do
      expect(helper.combat_action_icon(:attack)).to include("⚔")
    end

    it "returns shield icon for block" do
      expect(helper.combat_action_icon(:block)).to include("🛡")
    end

    it "returns magic icon for skill" do
      expect(helper.combat_action_icon(:skill)).to include("✨")
    end
  end

  describe "#body_part_label" do
    it "returns localized label for head" do
      expect(helper.body_part_label("head")).to eq("Head")
    end

    it "titleizes unknown parts" do
      expect(helper.body_part_label("torso")).to eq("Torso")
    end
  end

  describe "#damage_color_class" do
    it "returns critical class for high damage" do
      expect(helper.damage_color_class(50, 100)).to include("critical")
    end

    it "returns warning class for medium damage" do
      expect(helper.damage_color_class(25, 100)).to include("warning")
    end

    it "returns normal class for low damage" do
      expect(helper.damage_color_class(10, 100)).to include("normal")
    end
  end

  describe "#magic_icon" do
    it "returns fire icon for fire element" do
      expect(helper.magic_icon("fire")).to eq("🔥")
    end

    it "returns ice icon for water element" do
      expect(helper.magic_icon("water")).to eq("❄️")
    end

    it "returns ice icon for ice element" do
      expect(helper.magic_icon("ice")).to eq("❄️")
    end

    it "returns earth icon for earth element" do
      expect(helper.magic_icon("earth")).to eq("🪨")
    end

    it "returns lightning icon for air element" do
      expect(helper.magic_icon("air")).to eq("⚡")
    end

    it "returns heal icon for heal type" do
      expect(helper.magic_icon("heal")).to eq("💚")
    end

    it "returns shield icon for shield type" do
      expect(helper.magic_icon("shield")).to eq("🛡️")
    end

    it "returns damage icon for damage type" do
      expect(helper.magic_icon("damage")).to eq("⚔️")
    end

    it "returns default icon for unknown element" do
      expect(helper.magic_icon("unknown")).to eq("🔮")
    end

    it "handles symbol input" do
      expect(helper.magic_icon(:fire)).to eq("🔥")
    end
  end

  describe "#entry_class_for" do
    it "returns critical class for critical hits" do
      expect(helper.entry_class_for("CRITICAL HIT!")).to include("critical")
    end

    it "returns damage class for attack messages" do
      expect(helper.entry_class_for("You attack for 25 damage")).to include("damage")
    end

    it "returns heal class for healing messages" do
      expect(helper.entry_class_for("Healed for 30 HP")).to include("heal")
    end

    it "returns result class for victory" do
      expect(helper.entry_class_for("Victory!")).to include("result")
    end

    it "returns flee class for escape messages" do
      expect(helper.entry_class_for("You escaped!")).to include("flee")
    end

    it "returns info class for generic messages" do
      expect(helper.entry_class_for("Combat started")).to include("info")
    end
  end
end
