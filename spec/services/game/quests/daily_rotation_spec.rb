# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::DailyRotation do
  let(:character) { create(:character) }
  let!(:daily_quest) { create(:quest, quest_type: :daily, key: "daily_1", sequence: 1, daily_reset_slot: "morning") }

  describe "#refresh!" do
    it "ensures pending assignments for each daily slot" do
      slots = described_class.new(character:).refresh!

      expect(slots.keys).to include("morning")
      expect(slots["morning"].first).to be_pending
    end
  end
end
