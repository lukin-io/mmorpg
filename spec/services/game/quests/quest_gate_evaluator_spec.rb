# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::QuestGateEvaluator do
  let(:quest_chain) { create(:quest_chain) }
  let(:chapter) { create(:quest_chapter, quest_chain:, level_gate: 10, reputation_gate: 40, faction_alignment: "alliance") }
  let(:quest) { create(:quest, quest_chain:, quest_chapter: chapter, min_level: 12, min_reputation: 55) }

  describe "#call" do
    context "when character satisfies quest and chapter gates" do
      let(:character) { create(:character, level: 20, reputation: 80, faction_alignment: "alliance") }

      it "returns an allowed result" do
        result = described_class.new(character:, quest:).call

        expect(result).to be_allowed
        expect(result.reasons).to be_empty
      end

      it "merges extra requirements" do
        result = described_class.new(
          character:,
          quest:,
          extra_requirements: {min_level: 5, faction_alignment: ["alliance"]}
        ).call

        expect(result).to be_allowed
      end
    end

    context "when character misses requirements" do
      let(:character) { create(:character, level: 5, reputation: 5, faction_alignment: "neutral") }

      it "returns reasons for each failing gate" do
        result = described_class.new(character:, quest:).call

        expect(result).not_to be_allowed
        expect(result.reasons.map { |failure| failure[:type] }).to contain_exactly(:level, :reputation, :faction_alignment)
      end
    end
  end
end
