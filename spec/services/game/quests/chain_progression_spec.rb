# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::ChainProgression do
  let(:character) { create(:character) }
  let(:quest_chain) { create(:quest_chain, key: "main_story") }
  let!(:quest_one) { create(:quest, quest_chain:, sequence: 1) }
  let!(:quest_two) { create(:quest, quest_chain:, sequence: 2) }

  describe "#unlock_available!" do
    it "creates assignments sequentially once prerequisites are met" do
      assignments = described_class.new(character:, quest_chain:).unlock_available!
      expect(assignments.map(&:quest)).to include(quest_one)
      expect(assignments.map(&:quest)).not_to include(quest_two)

      QuestAssignment.find_by(quest: quest_one, character:).update!(status: :completed)

      assignments = described_class.new(character:, quest_chain:).unlock_available!
      expect(assignments.map(&:quest)).to include(quest_two)
    end
  end
end
