# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlignmentHelper, type: :helper do
  describe "#alignment_icon" do
    it "returns source-backed Neverlands alignment labels" do
      expect(helper.alignment_icon(:light)).to eq("Свет")
      expect(helper.alignment_icon(:dark)).to eq("Тьма")
      expect(helper.alignment_icon(:balance)).to eq("Равновесие")
    end
  end

  describe "#alignment_badge" do
    let(:character) do
      build(:character, alignment: "light")
    end

    it "returns alignment badge with labels" do
      result = helper.alignment_badge(character)
      expect(result).to include("Свет")
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
      expect(result).to include("Тьма")
    end
  end
end
