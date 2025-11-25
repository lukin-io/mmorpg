# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::QuestSnapshotCalculator do
  include ActiveSupport::Testing::TimeHelpers

  let(:quest_chain) { create(:quest_chain) }
  let(:quest) { create(:quest, quest_chain:) }

  around do |example|
    travel_to(Time.zone.parse("2025-01-01 12:00:00 UTC")) { example.run }
  end

  it "returns completion/abandon rates, averages, and bottleneck metadata" do
    quest.quest_steps.create!(position: 2, step_type: "dialogue", npc_key: "warden_lyra", content: {})
    create(:quest_assignment,
      quest:,
      character: create(:character),
      status: :completed,
      started_at: 40.minutes.ago,
      completed_at: 10.minutes.ago,
      updated_at: Time.current)
    create(:quest_assignment,
      quest:,
      character: create(:character),
      status: :failed,
      progress: {"current_step_position" => 2},
      abandoned_at: Time.current,
      updated_at: Time.current)
    stale = create(:quest_assignment,
      quest:,
      character: create(:character),
      status: :completed,
      updated_at: Time.current)
    stale.update_columns(updated_at: 2.months.ago)

    result = described_class.new(quest_chain:, window: 7.days).call

    expect(result[:completion_rate]).to eq(50.0)
    expect(result[:abandon_rate]).to eq(50.0)
    expect(result[:avg_minutes]).to eq(30)
    expect(result[:bottleneck_step_position]).to eq(2)
    expect(result[:bottleneck_step_key]).to eq("warden_lyra")
  end
end
