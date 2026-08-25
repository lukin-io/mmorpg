# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcLootAwarder do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:arena_match) { create(:arena_match, :live) }
  let!(:player_participation) do
    create(:arena_participation, arena_match:, character:, user:, team: "a")
  end
  let(:npc_template) { create(:npc_template, metadata: {"loot_table" => loot_table}) }
  let!(:npc_participation) do
    create(:arena_participation, :npc, arena_match:, npc_template:, team: "b")
  end
  let(:rng) { instance_double(Random, rand: 0) }
  let(:loot_table) { [] }

  subject(:award_loot) do
    described_class.new(
      match: arena_match,
      npc_participation:,
      character:,
      rng:
    ).call
  end

  context "with an item entry" do
    let!(:item_template) do
      create(:item_template, :consumable, key: "small_strange_potion", name: "Small strange potion")
    end
    let(:loot_table) do
      [
        {
          "kind" => "item",
          "item" => "small_strange_potion",
          "quantity" => 1,
          "chance" => 1.0
        }
      ]
    end

    it "persists the item before publishing the personal search result" do
      result = award_loot

      expect(result.awards.first).to be_item
      expect(character.inventory.inventory_items.find_by!(item_template:).quantity).to eq(1)
      expect(player_participation.reload.metadata["loot_drops"].last).to include(
        "kind" => "item",
        "item_key" => "small_strange_potion",
        "item_name" => "Small strange potion",
        "quantity" => 1
      )
      expect(npc_participation.reload.metadata.dig("loot_resolution", "awards", 0)).to include(
        "kind" => "item",
        "item_template_id" => item_template.id
      )
      expect(GameEvent.find_by!(event_type: :item_found, recipient: user).payload).to include(
        "item_name" => "Small strange potion",
        "item_template_id" => item_template.id
      )
    end
  end

  context "with an NV entry" do
    let(:loot_table) do
      [
        {
          "kind" => "currency",
          "currency" => "NV",
          "amount" => 24,
          "chance" => 1.0
        }
      ]
    end

    it "persists the wallet credit and transaction before publishing the money result" do
      expect { award_loot }.to change { user.currency_wallet.reload.nv_balance }.by(24)

      transaction = user.currency_wallet.currency_transactions.find_by!(reason: "combat.npc_loot")
      expect(transaction).to have_attributes(amount: 24, balance_after: 24)
      expect(transaction.metadata).to include(
        "arena_match_id" => arena_match.id,
        "character_id" => character.id,
        "npc_participation_id" => npc_participation.id
      )
      expect(player_participation.reload.metadata["loot_awards"].last).to include(
        "kind" => "currency",
        "currency" => "NV",
        "amount" => 24,
        "currency_transaction_id" => transaction.id
      )
      expect(GameEvent.find_by!(event_type: :money_found, recipient: user).payload).to include(
        "amount" => 24,
        "currency" => "NV",
        "currency_transaction_id" => transaction.id
      )
    end

    it "does not credit or publish twice when processing is retried" do
      first = award_loot
      second = described_class.new(
        match: arena_match,
        npc_participation:,
        character:,
        rng:
      ).call

      expect(first.already_processed?).to be false
      expect(second.already_processed?).to be true
      expect(user.currency_wallet.reload.nv_balance).to eq(24)
      expect(user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot").count).to eq(1)
      expect(GameEvent.where(event_type: :money_found, recipient: user).count).to eq(1)
    end

    it "rolls back the wallet and processing marker if event publication fails" do
      publisher = instance_double(Chat::EventPublisher)
      allow(publisher).to receive(:money_found!).and_raise("publisher unavailable")
      awarder = described_class.new(
        match: arena_match,
        npc_participation:,
        character:,
        rng:,
        event_publisher: publisher
      )

      expect { awarder.call }.to raise_error("publisher unavailable")
      expect(user.currency_wallet.reload.nv_balance).to eq(0)
      expect(user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot")).to be_empty
      expect(npc_participation.reload.metadata).not_to have_key("loot_resolution")
    end
  end

  context "when an item cannot enter inventory" do
    let!(:item_template) do
      create(:item_template, :material, key: "heavy_loot", name: "Heavy loot", weight: 2)
    end
    let(:loot_table) do
      [{"kind" => "item", "item_key" => "heavy_loot", "chance" => 1.0}]
    end

    it "persists no item and publishes no success event" do
      character.inventory.update!(current_weight: character.inventory.max_weight)

      result = award_loot

      expect(result.awards).to be_empty
      expect(result.failures.map(&:message)).to include("Inventory is overloaded")
      expect(character.inventory.inventory_items.where(item_template:)).to be_empty
      expect(GameEvent.where(event_type: :item_found, recipient: user)).to be_empty
      expect(npc_participation.reload.metadata.dig("loot_resolution", "failures")).to be_present
    end
  end

  context "when only part of a multi-unit item award fits" do
    let!(:item_template) do
      create(
        :item_template,
        :material,
        key: "partial_fit_loot",
        name: "Partial fit loot",
        weight: 1,
        stack_limit: 10
      )
    end
    let!(:existing_stack) do
      character.inventory.inventory_items.create!(
        item_template:,
        quantity: 8,
        weight: item_template.weight
      )
    end
    let(:loot_table) do
      [
        {
          "kind" => "item",
          "item_key" => "partial_fit_loot",
          "quantity" => 5,
          "chance" => 1.0
        }
      ]
    end

    before do
      character.inventory.update!(slot_capacity: 1, current_weight: 8)
    end

    it "records one failed resolution without retaining the portion that initially fit" do
      result = award_loot

      expect(result.awards).to be_empty
      expect(result.failures.map(&:message)).to contain_exactly("No free inventory slots")
      expect(existing_stack.reload.quantity).to eq(8)
      expect(character.inventory.reload.current_weight).to eq(8)
      expect(GameEvent.where(event_type: :item_found, recipient: user)).to be_empty
      expect(npc_participation.reload.metadata.dig("loot_resolution", "failures")).to be_present
    end
  end

  context "with a malformed entry" do
    let(:loot_table) { ["not-an-object"] }

    it "records the failure without inventing an award" do
      result = award_loot

      expect(result.awards).to be_empty
      expect(result.failures.map(&:message)).to contain_exactly("Loot entry must be an object")
      expect(GameEvent.where(recipient: user)).to be_empty
      expect(npc_participation.reload.metadata.dig("loot_resolution", "failures")).to be_present
    end
  end

  context "with an entry that omits chance" do
    let(:loot_table) do
      [{"kind" => "item", "item_key" => "unresolved_probability", "quantity" => 1}]
    end

    it "records a configuration failure instead of changing the old zero-percent default to a guaranteed drop" do
      result = award_loot

      expect(result.awards).to be_empty
      expect(result.failures.map(&:message)).to contain_exactly("Loot chance is required")
      expect(character.inventory.inventory_items).to be_empty
      expect(GameEvent.where(recipient: user)).to be_empty
    end
  end

  context "when the recipient is not a match participant" do
    it "rejects the award before changing authoritative state" do
      player_participation.destroy!

      expect { award_loot }.to raise_error(
        described_class::InvalidParticipantError,
        "Loot recipient must participate in the match"
      )
      expect(user.currency_wallet.reload.nv_balance).to eq(0)
      expect(npc_participation.reload.metadata).not_to have_key("loot_resolution")
    end
  end
end
