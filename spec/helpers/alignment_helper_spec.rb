# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlignmentHelper, type: :helper do
  describe "#faction_icon" do
    it "returns shield for alliance" do
      expect(helper.faction_icon(:alliance)).to eq("🛡️")
    end

    it "returns sword for rebellion" do
      expect(helper.faction_icon(:rebellion)).to eq("⚔️")
    end

    it "returns flag for neutral" do
      expect(helper.faction_icon(:neutral)).to eq("🏳️")
    end
  end

  describe "#alignment_tier_icon" do
    it "returns celestial icon for celestial tier" do
      expect(helper.alignment_tier_icon(:celestial)).to eq("👼")
    end

    it "returns yin-yang for neutral tier" do
      expect(helper.alignment_tier_icon(:neutral)).to eq("☯️")
    end

    it "returns black heart for absolute_darkness" do
      expect(helper.alignment_tier_icon(:absolute_darkness)).to eq("🖤")
    end
  end

  describe "#chaos_tier_icon" do
    it "returns scales for lawful" do
      expect(helper.chaos_tier_icon(:lawful)).to eq("⚖️")
    end

    it "returns explosion for absolute_chaos" do
      expect(helper.chaos_tier_icon(:absolute_chaos)).to eq("💥")
    end
  end

  describe "#trauma_badge" do
    it "returns green heart for low trauma" do
      result = helper.trauma_badge(10)
      expect(result).to include("💚")
      expect(result).to include("Low")
    end

    it "returns red heart for very high trauma" do
      result = helper.trauma_badge(80)
      expect(result).to include("❤️")
      expect(result).to include("Very High")
    end
  end

  describe "#timeout_badge" do
    it "displays timeout with icon" do
      result = helper.timeout_badge(180)
      expect(result).to include("⏱️")
      expect(result).to include("3min")
    end
  end

  describe "#location_icon" do
    it "returns castle for city" do
      expect(helper.location_icon(:city)).to eq("🏰")
    end

    it "returns tree for nature" do
      expect(helper.location_icon(:nature)).to eq("🌲")
    end

    it "returns stadium for arena" do
      expect(helper.location_icon(:arena)).to eq("🏟️")
    end
  end

  describe "#alignment_badge" do
    let(:character) do
      build(:character, faction_alignment: "alliance", alignment_score: 600)
    end

    it "returns alignment badge with icons" do
      result = helper.alignment_badge(character)
      expect(result).to include("🛡️") # faction
      expect(result).to include("✨")  # true light tier
      expect(result).to include("True Light")
    end

    it "returns empty string for nil character" do
      expect(helper.alignment_badge(nil)).to eq("")
    end
  end

  describe "#character_nameplate" do
    let(:character) do
      build(:character, name: "TestHero", level: 10, faction_alignment: "rebellion", alignment_score: 0)
    end

    it "includes character name" do
      result = helper.character_nameplate(character)
      expect(result).to include("TestHero")
    end

    it "includes level when show_level is true" do
      result = helper.character_nameplate(character, show_level: true)
      expect(result).to include("[10]")
    end

    it "includes alignment icons" do
      result = helper.character_nameplate(character)
      expect(result).to include("⚔️") # rebellion faction
    end
  end
end
