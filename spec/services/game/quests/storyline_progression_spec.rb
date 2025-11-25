# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::StorylineProgression do
  let(:character) { create(:character, level: 12, reputation: 35, faction_alignment: "alliance") }
  let(:quest_chain) { create(:quest_chain, key: "main_story") }
  let!(:chapter_one) do
    create(:quest_chapter,
      quest_chain:,
      position: 1,
      level_gate: 5,
      reputation_gate: 20,
      faction_alignment: "alliance")
  end
  let!(:chapter_two) do
    create(:quest_chapter,
      quest_chain:,
      position: 2,
      level_gate: 15,
      reputation_gate: 40,
      faction_alignment: "alliance")
  end
  let!(:quest_one) do
    create(:quest,
      quest_chain:,
      quest_chapter: chapter_one,
      sequence: 1,
      min_level: 5,
      min_reputation: 20)
  end
  let!(:quest_two) do
    create(:quest,
      quest_chain:,
      quest_chapter: chapter_two,
      sequence: 2,
      min_level: 15,
      min_reputation: 40)
  end

  describe "#unlock_available!" do
    it "unlocks quests sequentially once prerequisites are completed" do
      first_pass = described_class.new(character:, quest_chain:).unlock_available!
      expect(first_pass.map(&:quest)).to contain_exactly(quest_one)

      QuestAssignment.find_by(quest: quest_one, character:).update!(status: :completed)
      character.update!(level: 20, reputation: 60)

      second_pass = described_class.new(character:, quest_chain:).unlock_available!
      expect(second_pass.map(&:quest)).to include(quest_two)
    end

    it "blocks chapters when gates are not satisfied" do
      character.update!(level: 10, reputation: 10)

      assignments = described_class.new(character:, quest_chain:).unlock_available!

      expect(assignments).to be_empty
      expect(QuestAssignment.exists?(quest: quest_one, character:)).to be(false)
      expect(QuestAssignment.exists?(quest: quest_two, character:)).to be(false)
    end
  end
end
