# frozen_string_literal: true

require "rails_helper"

RSpec.describe GameEvent, type: :model do
  describe "audience invariants" do
    it "accepts recipient-only system information" do
      expect(build(:game_event)).to be_valid
    end

    it "accepts recipient-only money-found information" do
      expect(build(:game_event, :money_found)).to be_valid
    end

    it "accepts an untargeted world announcement" do
      expect(build(:game_event, :world_announcement)).to be_valid
    end

    it "rejects a personal event without a recipient" do
      event = build(:game_event, recipient: nil)

      expect(event).not_to be_valid
      expect(event.errors[:recipient]).to include("is required for personal game events")
    end

    it "rejects a world announcement with a recipient" do
      event = build(:game_event, :world_announcement, recipient: build(:user))

      expect(event).not_to be_valid
      expect(event.errors[:recipient]).to include("must be empty for world announcements")
    end
  end

  describe ".visible_to" do
    it "returns global and own events without exposing another recipient's event" do
      viewer = create(:user)
      other_user = create(:user)
      global_event = create(:game_event, :world_announcement)
      own_event = create(:game_event, recipient: viewer)
      create(:game_event, recipient: other_user)

      expect(described_class.visible_to(viewer)).to contain_exactly(global_event, own_event)
    end

    it "returns only global events for a null viewer" do
      global_event = create(:game_event, :world_announcement)
      create(:game_event)

      expect(described_class.visible_to(nil)).to contain_exactly(global_event)
    end
  end

  it "is immutable after creation" do
    event = create(:game_event)

    expect { event.update!(body: "Changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "backs event identity, type, audience, and payload shape with database constraints" do
    columns = described_class.columns_hash
    constraint_names = described_class.connection
      .check_constraints(described_class.table_name)
      .map(&:name)

    expect(columns.fetch("event_key").null).to be false
    expect(columns.fetch("occurred_at").null).to be false
    expect(described_class.connection.index_exists?(:game_events, :event_key, unique: true)).to be true
    expect(constraint_names).to include(
      "game_events_type_check",
      "game_events_audience_check",
      "game_events_payload_object_check"
    )
  end
end
