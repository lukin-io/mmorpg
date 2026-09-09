# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PerformLocalAction do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Outpost Surroundings", location_type: "outdoor") }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }
  let(:tile) { create(:map_tile_template, :with_resource_search, zone: zone.name, x: 5, y: 5) }
  let(:local_action_type) { "resource_search" }
  let(:action_offer) do
    create(:world_action_offer, :accepted, character:, zone:, x: 5, y: 5, target: tile,
      action_type: MapTileTemplate.world_action_type_for(local_action_type))
  end

  around { |example| freeze_time { example.run } }

  subject(:result) do
    described_class.new(character:, tile:, local_action_type:, action_offer:).call
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
    digging_tile = create(:map_tile_template, zone: zone.name, x: 5, y: 5,
      metadata: {"local_actions" => [{"type" => "digging", "source_id" => "dig"}]})

    digging_result = described_class.new(
      character:,
      tile: digging_tile,
      local_action_type: "digging",
      action_offer: nil
    ).call

    expect(digging_result.success).to be false
    expect(digging_result.message).to include("not implemented")
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

  it "snapshots configured duration using the injected server clock and never retimes a retry" do
    data = YAML.safe_load_file(Game::World::Rules::CONFIG_PATH, aliases: false)
    data.dig("local_actions", "resource_search")["duration_seconds"] = 40
    rules = Game::World::Rules.new(data:)
    started_at = Time.current + 5.seconds
    first = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer:,
      rules:, clock: -> { started_at }).call

    expect(first.success).to be true
    expect(action_offer.reload.local_action_ends_at).to eq(started_at + 40.seconds)

    repeated = described_class.new(character:, tile:, local_action_type: "resource_search", action_offer:,
      clock: -> { started_at + 10.seconds }).call

    expect(repeated.success).to be true
    expect(action_offer.reload.local_action_ends_at).to eq(started_at + 40.seconds)
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

  context "when entering fishing without bait at an authored water cell" do
    let(:local_action_type) { "fishing" }
    let(:tile) { create(:map_tile_template, :with_fishing, zone: zone.name, x: 5, y: 5) }

    it "keeps the captured empty-bait result and 30-second lock without a catch, fatigue gain or proficiency" do
      character.update!(fatigue_percent: 7, fatigue_updated_at: Time.current, passive_skills: {})
      original_skills = character.passive_skills
      action_offer

      expect { result }.not_to change(InventoryItem, :count)
      expect(result.success).to be true
      expect(result.message).to eq("No bait available.")
      expect(action_offer.reload.local_action_ends_at).to eq(Time.current + 30.seconds)
      expect(character.reload.fatigue_percent).to eq(7)
      expect(character.passive_skills).to eq(original_skills)
      expect(Game::World::LocalActionState.new(character:).call).to eq(action_offer)

      travel 10.seconds
      repeated = described_class.new(character:, tile:, local_action_type:, action_offer:).call
      expect(repeated.message).to eq("No bait available.")
      expect(action_offer.reload.local_action_remaining_seconds).to eq(20)
      expect(character.reload.fatigue_percent).to eq(7)
    end
  end

  context "when drinking at an authored water cell" do
    let(:local_action_type) { "drinking" }
    let(:tile) do
      create(:map_tile_template, zone: zone.name, x: 5, y: 5,
        metadata: {"local_actions" => [{"type" => "drinking", "source_id" => "dri"}]})
    end

    before { character.update!(fatigue_percent: 7, fatigue_updated_at: Time.current, passive_skills: {}, perks: {}) }

    it "immediately recovers two fatigue points without a skill gate and persists the 60-second lock" do
      action_offer
      expect { result }.not_to change(InventoryItem, :count)

      expect(result.success).to be true
      expect(result.message).to eq("Everything went well.")
      expect(character.reload.fatigue_percent).to eq(5)
      expect(action_offer.reload.local_action_ends_at).to eq(Time.current + 60.seconds)
      expect(action_offer.metadata).to include("fatigue_recovery_points" => 2, "fatigue_recovery_applied" => 2,
        "fatigue_recovered_at" => Time.current.iso8601(6))
      expect(Game::World::LocalActionState.new(character:).call).to eq(action_offer)
      expect(position.reload).to have_attributes(x: 5, y: 5)
    end

    it "does not recover again or restart the timer when retried before or after completion" do
      result
      original_metadata = action_offer.reload.metadata
      travel 10.seconds
      repeated = described_class.new(character:, tile:, local_action_type:, action_offer:).call

      expect(repeated.success).to be true
      expect(character.reload.fatigue_percent).to eq(5)
      expect(action_offer.reload.metadata).to eq(original_metadata)
      travel 50.seconds
      completed = described_class.new(character:, tile:, local_action_type:, action_offer:).call

      expect(completed.success).to be true
      expect(action_offer.reload).to be_completed
      expect(character.reload.fatigue_percent).to eq(5)
      expect(action_offer.metadata).to eq(original_metadata)
    end

    it "clamps recovery to the fatigue actually remaining" do
      character.update!(fatigue_percent: 1)

      expect(result.success).to be true
      expect(character.reload.fatigue_percent).to eq(0)
      expect(action_offer.reload.metadata["fatigue_recovery_applied"]).to eq(1)
    end

    it "does not grant an unsupported Nature Child perk from a stored unknown key" do
      character.update!(perks: {"nature_child" => true})

      expect(result.success).to be true
      expect(character.reload.fatigue_percent).to eq(5)
    end

    it "does not recover fatigue after the action is removed" do
      action_offer
      tile.update!(metadata: {})

      expect(result.success).to be false
      expect(character.reload.fatigue_percent).to eq(7)
      expect(action_offer.reload.local_action_ends_at).to be_nil
    end

    it "rolls back recovery if the persisted action result cannot be committed" do
      action_offer
      allow(MapTileTemplate).to receive(:default_local_action_message).with("drinking").and_return(nil)

      expect { result }.to raise_error(ActiveRecord::RecordInvalid, /local action result/)
      expect(character.reload.fatigue_percent).to eq(7)
      expect(action_offer.reload.local_action_ends_at).to be_nil
    end

    it "does not apply recovery when a hostile encounter replaces the sip" do
      interrupted = Game::World::InterruptAction::Result.new(interrupted: true, message: "A hostile attacks.")
      interrupt_service = instance_double(Game::World::InterruptAction, call: interrupted)
      allow(Game::World::InterruptAction).to receive(:new).with(character:).and_return(interrupt_service)

      expect(result.interruption).to eq(interrupted)
      expect(character.reload.fatigue_percent).to eq(7)
      expect(action_offer.reload.local_action_ends_at).to be_nil
    end
  end
end
