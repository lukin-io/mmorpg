# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chat::EventPublisher do
  let(:timestamp) { Time.zone.parse("2026-08-23 20:09:05") }
  let(:publisher) { described_class.new(clock: -> { timestamp }) }
  let(:recipient) { create(:user) }

  it "records a structured fight-completion event" do
    event = publisher.fight_finished!(
      recipient:,
      experience: 749,
      event_key: "arena-match:12:participation:34:finished",
      payload: {arena_match_id: 12}
    )

    expect(event).to have_attributes(
      recipient:,
      event_type: "fight_finished",
      body: "Fight finished.",
      occurred_at: timestamp
    )
    expect(event.payload).to include("arena_match_id" => 12, "experience" => 749)
  end

  it "records an item-found event with normalized quantity" do
    event = publisher.item_found!(
      recipient:,
      item_name: " Small strange potion ",
      quantity: 0,
      event_key: "arena-match:12:loot:0"
    )

    expect(event).to be_item_found
    expect(event.payload).to include("item_name" => "Small strange potion", "quantity" => 1)
  end

  it "records a deposited NV search result" do
    event = publisher.money_found!(
      recipient:,
      amount: 24,
      event_key: "arena-match:12:money:0"
    )

    expect(event).to be_money_found
    expect(event.payload).to include("amount" => 24, "currency" => "NV")
  end

  it "records a global world announcement without a recipient" do
    event = publisher.world_announcement!(
      body: "The outpost is under attack.",
      event_key: "world-event:outpost:42"
    )

    expect(event).to be_world_announcement
    expect(event).to be_global
  end

  it "returns the same event for a retried stable key" do
    attributes = {
      recipient:,
      body: "A path opened.",
      event_key: "system:recipient:#{recipient.id}:path-opened"
    }

    first = publisher.system_information!(**attributes)
    second = publisher.system_information!(**attributes)

    expect(second).to eq(first)
    expect(GameEvent.where(event_key: attributes[:event_key]).count).to eq(1)
  end

  it "rejects reuse of a key for a different event identity" do
    publisher.system_information!(
      recipient:,
      body: "First body.",
      event_key: "conflicting-key"
    )

    expect do
      publisher.system_information!(
        recipient:,
        body: "Different body.",
        event_key: "conflicting-key"
      )
    end.to raise_error(Chat::EventPublisher::EventKeyConflict)
  end

  it "rejects an item event without an item name" do
    expect do
      publisher.item_found!(recipient:, item_name: " ", quantity: 1, event_key: "missing-item")
    end.to raise_error(ArgumentError, "item name is required")
  end

  it "rejects non-positive or unsupported money awards" do
    expect do
      publisher.money_found!(recipient:, amount: 0, event_key: "missing-money")
    end.to raise_error(ArgumentError, "money amount must be a positive integer")

    expect do
      publisher.money_found!(recipient:, amount: 24, currency: "DNV", event_key: "wrong-currency")
    end.to raise_error(ArgumentError, "unsupported money currency")
  end
end
