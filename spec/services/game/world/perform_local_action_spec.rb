# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PerformLocalAction do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5) }
  let(:action_offer) do
    create(:world_action_offer, :accepted, character:, zone:, x: 5, y: 5, target: tile)
  end

  around { |example| freeze_time { example.run } }

  subject(:result) do
    described_class.new(character:, tile:, local_action_type: "resource_search", action_offer:).call
  end

  it "starts the captured deadline with an immediate result and no invented resource reward" do
    action_offer
    expect { result }.not_to change(InventoryItem, :count)

    expect(result.success).to be true
    expect(result.message).to eq("There is no useful vegetation in this area.")
    expect(action_offer.reload).to be_accepted
    expect(action_offer.local_action_ends_at).to eq(Time.current + 28.seconds)
    expect(action_offer.local_action_result).to eq(result.message)
    expect(position.reload).to have_attributes(x: 5, y: 5)
  end

  it "uses an authored source-backed result message when present" do
    tile.update!(
      metadata: tile.metadata.deep_merge(
        "local_actions" => [
          {
            "type" => "resource_search",
            "source_id" => "look",
            "result_message" => "Nothing was found."
          }
        ]
      )
    )

    expect(result.message).to eq("Nothing was found.")
  end

  it "rejects an inactive local action" do
    tile.update!(
      metadata: {
        "local_actions" => [
          {"type" => "resource_search", "source_id" => "look", "active" => false}
        ]
      }
    )

    expect(result.success).to be false
    expect(result.message).to include("no longer available")
  end

  it "rejects a tile outside the character's current position" do
    position.update!(x: 6)

    expect(result.success).to be false
    expect(result.message).to include("current cell")
  end

  it "rejects the action when the character has no persisted position" do
    position.destroy!

    expect(result.success).to be false
    expect(result.message).to include("current cell")
  end

  it "rejects a null action type" do
    null_result = described_class.new(character:, tile:, local_action_type: nil, action_offer:).call

    expect(null_result.success).to be false
  end

  it "rejects a captured action whose successful flow is still deferred" do
    fishing_tile = create(:map_tile_template, :with_fishing, zone: zone.name, x: 5, y: 5)

    fishing_result = described_class.new(
      character:,
      tile: fishing_tile,
      local_action_type: "fishing",
      action_offer: nil
    ).call

    expect(fishing_result.success).to be false
    expect(fishing_result.message).to include("not implemented")
  end

  it "returns the original result and deadline when the same started offer is retried" do
    first_result = result
    deadline = action_offer.reload.local_action_ends_at
    travel 10.seconds

    repeated = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer:).call

    expect(repeated.success).to be true
    expect(repeated.message).to eq(first_result.message)
    expect(action_offer.reload.local_action_ends_at).to eq(deadline)
    expect(action_offer.local_action_remaining_seconds).to eq(18)
  end

  it "does not restart a completed search when its original offer is retried" do
    result
    deadline = action_offer.reload.local_action_ends_at
    travel 28.seconds

    repeated = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer:).call

    expect(repeated.success).to be true
    expect(action_offer.reload).to be_completed
    expect(action_offer.local_action_ends_at).to eq(deadline)
  end

  it "cancels sibling movement and local-action offers when work starts" do
    movement = create(:movement_command, character:, zone:, from_x: 5, from_y: 5, target_x: 6, target_y: 5)
    sibling = create(:world_action_offer, character:, zone:, x: 5, y: 5, target: tile)

    result

    expect(movement.reload).to be_cancelled
    expect(sibling.reload).to be_cancelled
  end

  it "rejects another accepted action without resetting current work" do
    result
    deadline = action_offer.reload.local_action_ends_at
    other_offer = create(:world_action_offer, :accepted, character:, zone:, x: 5, y: 5, target: tile)

    other_result = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer: other_offer).call

    expect(other_result.success).to be false
    expect(other_result.message).to include("still in progress")
    expect(action_offer.reload.local_action_ends_at).to eq(deadline)
    expect(other_offer.reload.metadata).not_to have_key("local_action_ends_at")
  end

  it "rejects an unaccepted offer and an offer owned by another character" do
    action_offer.update!(status: :offered, accepted_at: nil)
    expect(result.success).to be false
    expect(action_offer.reload.metadata).not_to have_key("local_action_ends_at")

    foreign_offer = create(:world_action_offer, :accepted, zone:, x: 5, y: 5, target: tile)
    foreign_result = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer: foreign_offer).call

    expect(foreign_result.success).to be false
    expect(foreign_offer.reload.metadata).not_to have_key("local_action_ends_at")
  end

  it "rejects a mismatched target without starting a timer" do
    other_tile = create(:map_tile_template, :with_resource_search, zone: zone.name, x: 6, y: 5)
    action_offer.update!(target: other_tile)

    expect(result.success).to be false
    expect(result.message).to include("does not match")
    expect(action_offer.reload.metadata).not_to have_key("local_action_ends_at")
  end
end
