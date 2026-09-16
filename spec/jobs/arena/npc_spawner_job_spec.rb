# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcSpawnerJob do
  include ActiveJob::TestHelper
  let!(:room) { create(:arena_room, slug: "training", level_min: 0, level_max: 5) }

  it "replenishes after expiry, repeats safely and schedules the next default scan" do
    expect { described_class.perform_now }.to have_enqueued_job(described_class)
    first = room.arena_applications.open.sole
    2.times { described_class.perform_now(room_slug: "training") }
    expect(room.arena_applications.open.sole).to eq(first)
    first.update!(expires_at: Time.current)
    described_class.perform_now(room_slug: "training")
    expect(first.reload).to be_expired
    expect(room.arena_applications.open.sole.id).not_to eq(first.id)
  end

  it "ignores deleted, disabled and unconfigured rooms without a recurring chain" do
    room.update!(active: false)
    expect do
      %w[training missing].each { |slug| described_class.perform_now(room_slug: slug) }
    end.not_to have_enqueued_job(described_class)
    expect(ArenaApplication.count).to eq(0)
  end

  it "leaves committed supply intact if scheduling fails and repairs through replay" do
    scheduled = double("scheduled job")
    allow(described_class).to receive(:set).and_return(scheduled)
    allow(scheduled).to receive(:perform_later).and_raise(Redis::CannotConnectError)
    expect { described_class.perform_now }.to raise_error(Redis::CannotConnectError)
    expect(room.arena_applications.open.count).to eq(1)
    described_class.perform_now(room_slug: "training")
    expect(room.arena_applications.open.count).to eq(1)
  end
end
