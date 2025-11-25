# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestAnalyticsJob do
  include ActiveSupport::Testing::TimeHelpers

  let(:quest_chain) { create(:quest_chain, key: "main_story") }
  let(:quest) { create(:quest, quest_chain:) }

  around do |example|
    travel_to(Time.zone.parse("2025-01-02 09:00:00 UTC")) { example.run }
  end

  it "snapshots quest metrics per chain and upserts by date" do
    create(:quest_assignment, quest:, status: :completed, updated_at: Time.current)

    expect { described_class.perform_now(window: 7.days) }
      .to change(QuestAnalyticsSnapshot, :count).by(1)

    snapshot = QuestAnalyticsSnapshot.find_by(quest_chain_key: "main_story")
    expect(snapshot.captured_on).to eq(Date.current)

    expect { described_class.perform_now(window: 7.days) }
      .not_to change(QuestAnalyticsSnapshot, :count)
  end
end
