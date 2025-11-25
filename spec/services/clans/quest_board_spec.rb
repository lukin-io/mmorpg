# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clans::QuestBoard do
  let(:clan) { create(:clan) }
  let!(:quest) { create(:quest, key: "clan_defend_caravans") }
  subject(:board) { described_class.new(clan: clan) }

  describe "#start!" do
    it "creates a clan quest from the template" do
      expect { board.start!(template_key: "defend_caravans") }.to change { clan.clan_quests.count }.by(1)
    end
  end

  describe "#record_contribution!" do
    it "records progress and awards XP on completion" do
      quest_record = board.start!(template_key: "defend_caravans")
      character = create(:character)
      requirements = quest_record.requirements.keys.first
      required_amount = quest_record.requirements.values.first

      expect do
        board.record_contribution!(
          quest: quest_record,
          character: character,
          metric: requirements,
          amount: required_amount
        )
      end.to change { clan.reload.clan_xp_events.count }.by(1)
    end
  end
end
