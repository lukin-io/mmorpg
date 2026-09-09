# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaParticipation, type: :model do
  describe "#participant_level" do
    it "uses a positive captured level override for a sampled NPC" do
      participation = create(:arena_participation, :sampled_npc)

      expect(participation.participant_level).to eq(8)
    end

    it "falls back to the NPC template for a missing or invalid override" do
      template = create(:npc_template, level: 7)

      [nil, "unknown", -1, 0.5].each do |level|
        participation = create(
          :arena_participation,
          :npc,
          npc_template: template,
          metadata: {"current_hp" => 155, "max_hp" => 155, "level" => level}
        )

        expect(participation.participant_level).to eq(7)
      end
    end

    it "preserves a level-zero member override over a higher-level template" do
      template = create(:npc_template, level: 7)
      participation = create(:arena_participation, :npc, npc_template: template,
        metadata: {"current_hp" => 40, "max_hp" => 40, "level" => 0})

      expect(participation.reload.participant_level).to eq(0)
    end

    it "keeps player level authoritative on the character" do
      character = build(:character, level: 12)
      participation = build(:arena_participation, character:, metadata: {"level" => 99})

      expect(participation.participant_level).to eq(12)
    end
  end
end
