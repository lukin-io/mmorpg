# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Quests::RepeatableQuestScheduler do
  include ActiveSupport::Testing::TimeHelpers

  let(:character) { create(:character) }
  let!(:weekly_quest) { create(:quest, repeatable: true, quest_type: :weekly) }

  around do |example|
    travel_to(Time.zone.parse("2025-01-05 10:00:00 UTC")) { example.run }
  end

  describe "#refresh!" do
    it "creates pending assignments and schedules the next weekly reset" do
      assignments = described_class.new(character:, now: Time.current).refresh!

      expect(assignments.length).to eq(1)
      assignment = assignments.first
      expect(assignment).to be_pending
      expect(assignment.next_available_at).to eq((Time.current.beginning_of_week + 1.week).change(hour: 4))
    end

    it "skips assignments that are cooling down" do
      create(:quest_assignment,
        quest: weekly_quest,
        character:,
        status: :completed,
        next_available_at: 1.week.from_now + 1.day)

      assignments = described_class.new(character:, now: Time.current).refresh!

      expect(assignments).to be_empty
    end
  end
end
