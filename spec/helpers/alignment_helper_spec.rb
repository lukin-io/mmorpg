# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlignmentHelper, type: :helper do
  describe "#alignment_icon" do
    it "returns source-backed Neverlands alignment labels" do
      expect(helper.alignment_icon(:light)).to eq("Light")
      expect(helper.alignment_icon(:dark)).to eq("Dark")
      expect(helper.alignment_icon(:balance)).to eq("Balance")
    end
  end

  describe "#trauma_badge" do
    it "returns label for low trauma" do
      result = helper.trauma_badge(10)
      expect(result).to include("Low")
    end

    it "returns label for very high trauma" do
      result = helper.trauma_badge(80)
      expect(result).to include("Very High")
    end
  end

  describe "#timeout_badge" do
    it "displays timeout label" do
      result = helper.timeout_badge(180)
      expect(result).to include("3m")
    end
  end

  describe "#location_icon" do
    it "returns label for city" do
      expect(helper.location_icon(:city)).to eq("City")
    end

    it "returns label for nature" do
      expect(helper.location_icon(:nature)).to eq("Nature")
    end

    it "returns label for arena" do
      expect(helper.location_icon(:arena)).to eq("Arena")
    end
  end

  describe "#alignment_badge" do
    let(:character) do
      build(:character, alignment: "light")
    end

    it "returns alignment badge with labels" do
      result = helper.alignment_badge(character)
      expect(result).to include("Light")
    end

    it "returns empty string for nil character" do
      expect(helper.alignment_badge(nil)).to eq("")
    end
  end

  describe "#character_nameplate" do
    let(:character) do
      build(:character, name: "max_kerby_alignment", level: 10, alignment: "dark")
    end

    it "includes character name" do
      result = helper.character_nameplate(character)
      expect(result).to include("max_kerby_alignment")
    end

    it "includes level when show_level is true" do
      result = helper.character_nameplate(character, show_level: true)
      expect(result).to include("[10]")
    end

    it "includes alignment labels" do
      result = helper.character_nameplate(character)
      expect(result).to include("Dark")
    end
  end
end
