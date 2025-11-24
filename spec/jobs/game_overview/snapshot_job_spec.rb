# frozen_string_literal: true

require "rails_helper"

RSpec.describe GameOverview::SnapshotJob, type: :job do
  it "persists a snapshot" do
    expect do
      described_class.perform_now
    end.to change(GameOverviewSnapshot, :count).by(1)
  end
end
