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
end
