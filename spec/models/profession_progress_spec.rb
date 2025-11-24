require "rails_helper"

RSpec.describe ProfessionProgress do
  describe "slot limits" do
    it "prevents exceeding gathering slots per character" do
      character = create(:character)
      herbalism = create(:profession, category: "gathering", gathering: true)
      fishing = create(:profession, category: "gathering", gathering: true)
      hunting = create(:profession, category: "gathering", gathering: true)

      create(:profession_progress, character:, profession: herbalism, slot_kind: "gathering")
      create(:profession_progress, character:, profession: fishing, slot_kind: "gathering")

      progress = build(:profession_progress, character:, profession: hunting, slot_kind: "gathering")
      expect(progress).not_to be_valid
      expect(progress.errors[:base]).to include("Slot limit reached for gathering professions")
    end
  end

  describe "#gain_experience!" do
    it "levels up when thresholds are crossed" do
      progress = create(:profession_progress, skill_level: 1, experience: 0)

      expect { progress.gain_experience!(250) }.to change {
        progress.reload.skill_level
      }.from(1).to(2)
    end
  end
end
