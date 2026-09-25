# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::GatherYield do
  let(:zone) { create(:zone, name: "Пепельный Берег", location_type: "outdoor", width: 100, height: 100) }

  it "maps pine tree dig to pine_resin" do
    tile = create(:map_tile_template, zone: zone.name, x: 8, y: 8,
      metadata: {"resource_groups" => [{"key" => "pine", "kind" => "tree", "label" => "Сосна", "active" => true}]})
    result = described_class.new(tile:, local_action_type: "digging", rng: Random.new(1)).call
    expect(result.item_key).to eq("pine_resin")
  end

  it "maps herb look to ferns" do
    tile = create(:map_tile_template, zone: zone.name, x: 13, y: 6,
      metadata: {"resource_groups" => [{"key" => "ember_fern", "kind" => "herb", "label" => "Папоротник", "active" => true}]})
    result = described_class.new(tile:, local_action_type: "resource_search", rng: Random.new(1)).call
    expect(result.item_key).to eq("ember_fern")
  end

  it "maps fishing groups to fish keys" do
    tile = create(:map_tile_template, zone: zone.name, x: 30, y: 10,
      metadata: {"resource_groups" => [{"key" => "veil_eel", "kind" => "fish", "label" => "Угорь", "active" => true}]})
    result = described_class.new(tile:, local_action_type: "fishing", rng: Random.new(1)).call
    expect(result.item_key).to eq("veil_eel")
  end

  it "returns nil when the cell has no matching groups" do
    tile = create(:map_tile_template, zone: zone.name, x: 5, y: 5, metadata: {"resource_groups" => []})
    expect(described_class.new(tile:, local_action_type: "resource_search").call).to be_nil
  end

  it "reports depletion while every matching resource group is regrowing" do
    tile = create(:map_tile_template, zone: zone.name, x: 6, y: 6,
      metadata: {
        "resource_groups" => [{"key" => "pine", "kind" => "tree", "label" => "Pine", "active" => true}],
        "resource_depletion" => {"pine" => 10.minutes.from_now.iso8601}
      })

    result = described_class.new(tile:, local_action_type: "digging").call

    expect(result.depleted).to be(true)
    expect(result.item_key).to be_nil
  end
end

RSpec.describe Game::World::PerformLocalAction, "fishing with bait" do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Пепельный Берег", location_type: "outdoor", width: 100, height: 100) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 30, y: 10) }
  let(:tile) do
    create(:map_tile_template, zone: zone.name, x: 30, y: 10,
      metadata: {
        "local_actions" => [{"type" => "fishing", "source_id" => "fis", "active" => true}],
        "resource_groups" => [{"key" => "ash_perch", "kind" => "fish", "label" => "Окунь", "active" => true}]
      })
  end
  let(:action_offer) do
    create(:world_action_offer, :accepted, character:, zone:, x: 30, y: 10, target: tile,
      action_type: MapTileTemplate.world_action_type_for("fishing"))
  end

  around { |example| freeze_time { example.run } }

  before do
    Game::Professions::Templates.ensure_craft_items!
    Game::World::FishingCatalog.ensure_templates!
    inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
    Game::Inventory::Manager.new(inventory:).add_item!(
      item_template: ItemTemplate.find_by!(key: "hook_worm"),
      quantity: 2
    )
    Game::Inventory::Manager.new(inventory:).add_item!(
      item_template: ItemTemplate.find_by!(key: "ashen_fishing_rod"),
      quantity: 1
    )
  end

  it "consumes the matching hook and awards a fish" do
    result = described_class.new(
      character:, tile:, local_action_type: "fishing", action_offer:
    ).call

    expect(result.success).to be(true)
    expect(action_offer.reload.metadata["gather_item_key"]).to eq("ash_perch")
    expect(action_offer.metadata["hook_consumed"]).to eq(1)
    hooks_left = character.inventory.inventory_items.joins(:item_template)
      .where(item_templates: {key: "hook_worm"}).sum(:quantity)
    expect(hooks_left).to eq(1)
  end

  it "skips gather without the fishing rod" do
    rod = ItemTemplate.find_by!(key: "ashen_fishing_rod")
    character.inventory.inventory_items.where(item_template: rod).delete_all

    result = described_class.new(
      character:, tile:, local_action_type: "fishing", action_offer:
    ).call

    expect(result.success).to be(true)
    expect(action_offer.reload.metadata["gather_skipped"]).to eq("no_tool")
    expect(action_offer.metadata["gather_tool_key"]).to eq("ashen_fishing_rod")
  end

  it "skips gather without the matching hook" do
    hook = ItemTemplate.find_by!(key: "hook_worm")
    character.inventory.inventory_items.where(item_template: hook).delete_all

    result = described_class.new(
      character:, tile:, local_action_type: "fishing", action_offer:
    ).call

    expect(result.success).to be(true)
    expect(action_offer.reload.metadata["gather_skipped"]).to eq("no_hook")
  end
end

RSpec.describe Game::World::PerformLocalAction, "digging with hatchet" do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Пепельный Берег", location_type: "outdoor", width: 100, height: 100) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 8, y: 8) }
  let(:tile) do
    create(:map_tile_template, zone: zone.name, x: 8, y: 8,
      metadata: {
        "local_actions" => [{"type" => "digging", "source_id" => "dig", "active" => true}],
        "resource_groups" => [{"key" => "pine", "kind" => "tree", "label" => "Сосна", "active" => true}]
      })
  end
  let(:action_offer) do
    create(:world_action_offer, :accepted, character:, zone:, x: 8, y: 8, target: tile,
      action_type: MapTileTemplate.world_action_type_for("digging"))
  end

  around { |example| freeze_time { example.run } }

  before { Game::Professions::Templates.ensure_craft_items! }

  it "requires the hatchet" do
    result = described_class.new(
      character:, tile:, local_action_type: "digging", action_offer:
    ).call

    expect(result.success).to be(true)
    expect(action_offer.reload.metadata["gather_skipped"]).to eq("no_tool")
  end

  it "awards resin when the hatchet is owned" do
    inventory = character.inventory || character.create_inventory!(slot_capacity: 30, weight_capacity: 100)
    Game::Inventory::Manager.new(inventory:).add_item!(
      item_template: ItemTemplate.find_by!(key: "ashen_hatchet"),
      quantity: 1
    )

    result = described_class.new(
      character:, tile:, local_action_type: "digging", action_offer:
    ).call

    expect(result.success).to be(true)
    expect(action_offer.reload.metadata["gather_item_key"]).to eq("pine_resin")
    expect(tile.reload.metadata.dig("resource_depletion", "pine")).to be_present
  end

  it "wears the hatchet once after a successful gather" do
    inventory = character.inventory
    tool = Game::Inventory::Manager.new(inventory:).add_item!(
      item_template: ItemTemplate.find_by!(key: "ashen_hatchet"),
      quantity: 1
    )

    described_class.new(character:, tile:, local_action_type: "digging", action_offer:).call

    expect(tool.reload.current_durability).to eq(49)
  end

  it "fails the action when every tree group is depleted" do
    tile.update!(metadata: tile.metadata.deep_merge(
      "resource_depletion" => {"pine" => 10.minutes.from_now.iso8601}
    ))
    Game::Inventory::Manager.new(inventory: character.inventory).add_item!(
      item_template: ItemTemplate.find_by!(key: "ashen_hatchet"),
      quantity: 1
    )

    result = described_class.new(character:, tile:, local_action_type: "digging", action_offer:).call

    expect(result.success).to be(false)
    expect(result.message).to include("regrowing")
    expect(action_offer.reload.metadata["gather_skipped"]).to eq("depleted")
  end
end

RSpec.describe Game::World::PostOfficeMail do
  let(:sender) { create(:character, name: "SenderAsh#{SecureRandom.hex(3)}") }
  let(:recipient) { create(:character, name: "ReaderAsh#{SecureRandom.hex(3)}") }

  it "delivers a letter into the recipient inbox" do
    result = described_class.new(character: sender, body: "hello shore", recipient_name: recipient.name).send!
    expect(result.success).to be(true)
    inbox = described_class.inbox_for(recipient.reload)
    expect(inbox.first["body"]).to eq("hello shore")
    expect(inbox.first["from"]).to eq(sender.name)
  end
end

RSpec.describe Game::World::SectorWarBoard do
  it "lists active fortresses" do
    WorldFortress.create!(
      fortress_key: "fort_test_board",
      name: "Тест",
      zone: "Пепельный Берег",
      x: 3,
      y: 3,
      kind: "fortress",
      active: true
    )
    rows = described_class.new.call
    expect(rows.map(&:key)).to include("fort_test_board")
  end
end
