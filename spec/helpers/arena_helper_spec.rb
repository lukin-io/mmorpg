# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaHelper, type: :helper do
  describe "#room_type_icon" do
    it "returns training icon for training rooms" do
      expect(helper.room_type_icon("training")).to be_present
    end

    it "returns duel icon for duel rooms" do
      expect(helper.room_type_icon("duel")).to be_present
    end

    it "returns faction icon for faction rooms" do
      expect(helper.room_type_icon("faction")).to be_present
    end

    it "returns default icon for unknown types" do
      expect(helper.room_type_icon("unknown")).to be_present
    end
  end

  describe "#fight_type_label" do
    it "returns label for duel type" do
      expect(helper.fight_type_label("duel")).to eq("1v1 Duel")
    end

    it "returns label for group type" do
      expect(helper.fight_type_label("group")).to eq("Group Battle")
    end
  end

  describe "#level_range_display" do
    it "formats level range" do
      room = double(min_level: 1, max_level: 10)
      expect(helper.level_range_display(room)).to eq("Lvl 1-10")
    end

    it "handles same level" do
      room = double(min_level: 5, max_level: 5)
      expect(helper.level_range_display(room)).to eq("Lvl 5")
    end
  end
end
