# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::NpcLootAwarder do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:arena_match) { create(:arena_match, :live) }
  let!(:player_participation) do
    create(:arena_participation, arena_match:, character:, user:, team: "a")
  end
  let(:npc_template) { create(:npc_template, level: 1, metadata: {"loot_table" => loot_table}) }
  let!(:npc_participation) do
    create(:arena_participation, :npc, arena_match:, npc_template:, team: "b")
  end
  # Seeded RNG: low rolls succeed chance checks; ranged NV bonus stays deterministic.
  let(:rng) { Random.new(1) }
  let(:loot_table) { [] }

  subject(:award_loot) do
    described_class.new(
      match: arena_match,
      npc_participation:,
      character:,
      rng:
    ).call
  end

  def formula_nv_for(level)
    # Mirror awarder: level*3 + rand(1..(level*2).clamp(1,200)) with Random.new(1)
    hi = (level * 2).clamp(1, 200)
    bonus = Random.new(1).rand(1..hi)
    (level * 3) + bonus
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

      expect(result.awards.any?(&:item?)).to be(true)
      expect(character.inventory.inventory_items.find_by!(item_template:).quantity).to eq(1)
      expect(player_participation.reload.metadata["loot_drops"].last).to include(
        "kind" => "item",
        "item_key" => "small_strange_potion",
        "item_name" => "Small strange potion",
        "quantity" => 1
      )
      expect(npc_participation.reload.metadata.dig("loot_resolution", "awards")).to include(
        hash_including("kind" => "item", "item_template_id" => item_template.id)
      )
      expect(GameEvent.find_by!(event_type: :item_found, recipient: user).payload).to include(
        "item_name" => "Small strange potion",
        "item_template_id" => item_template.id
      )
    end

    it "always credits soft-release formula NV once per kill" do
      expect { award_loot }.to change { user.currency_wallet.reload.nv_balance }.by(formula_nv_for(1))
    end
  end

  context "with equipment item entries" do
    let!(:axe) do
      create(
        :item_template,
        key: "wilderness_axe",
        name: "Wilderness axe",
        slot: "main_hand",
        stat_modifiers: {"weapon_family" => "axe"}
      )
    end
    let!(:armor) do
      create(:item_template, :armor, key: "wilderness_armor", name: "Wilderness armor")
    end
    let(:loot_table) do
      [
        {"kind" => "item", "item" => axe.key, "chance" => 1.0},
        {"kind" => "item", "item" => armor.key, "chance" => 1.0}
      ]
    end

    it "awards at most one gear piece plus formula NV" do
      result = award_loot

      expect(result.awards.count(&:item?)).to eq(1)
      expect(result.awards.count(&:currency?)).to eq(1)
      expect(character.inventory.inventory_items.pluck(:item_template_id)).to contain_exactly(axe.id)
      expect(GameEvent.where(event_type: :item_found, recipient: user).count).to eq(1)
    end
  end

  context "with item and currency entries" do
    let!(:item_template) do
      create(:item_template, :consumable, key: "shared_lock_potion")
    end
    let(:loot_table) do
      [
        {"kind" => "item", "item" => item_template.key, "chance" => 1.0},
        {"kind" => "currency", "currency" => "NV", "amount" => 24, "chance" => 1.0}
      ]
    end

    it "locks the recipient before reward rows to match concurrent inventory requests" do
      locked_tables = []
      subscriber = lambda do |*, payload|
        next unless payload[:sql].include?("FOR UPDATE")

        locked_tables << payload[:sql][/FROM "([^"]+)"/, 1]
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        award_loot
      end

      expect(locked_tables.first).to eq("characters")
      expect(locked_tables).to include("arena_participations", "inventories", "currency_wallets")
      expect(character.inventory.inventory_items.find_by!(item_template:).quantity).to eq(1)
      expect(user.currency_wallet.reload.nv_balance).to eq(24 + formula_nv_for(1))
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
      expected = 24 + formula_nv_for(1)
      expect { award_loot }.to change { user.currency_wallet.reload.nv_balance }.by(expected)

      transaction = user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot").order(:id).last!
      expect(transaction.metadata).to include(
        "arena_match_id" => arena_match.id,
        "character_id" => character.id,
        "npc_participation_id" => npc_participation.id
      )
      expect(player_participation.reload.metadata["loot_awards"]).to include(
        hash_including("kind" => "currency", "currency" => "NV")
      )
      expect(GameEvent.where(event_type: :money_found, recipient: user).count).to be >= 1
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
      expect(user.currency_wallet.reload.nv_balance).to eq(24 + formula_nv_for(1))
      expect(user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot").count).to eq(2)
      expect(GameEvent.where(event_type: :money_found, recipient: user).count).to eq(2)
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

  context "when an item template is missing" do
    let(:loot_table) do
      [{"kind" => "item", "item_key" => "missing_loot_template", "chance" => 1.0, "rarity" => "common"}]
    end
    let(:rng) { instance_double(Random) }

    before do
      allow(rng).to receive(:rand) { |arg = nil| arg.is_a?(Range) ? 1 : 0.0 }
    end

    it "still credits formula NV and records the item failure" do
      result = award_loot

      expect(result.awards.count(&:currency?)).to eq(1)
      expect(result.failures.map(&:message)).to include(
        I18n.t("arena.validations.loot_item_missing", identity: "missing_loot_template")
      )
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

    it "still awards the overflowing stack without a hard slot failure" do
      result = award_loot

      expect(result.failures).to be_empty
      expect(result.awards.count(&:item?)).to eq(1)
      expect(character.inventory.inventory_items.where(item_template: existing_stack.item_template).sum(:quantity)).to eq(13)
      expect(character.inventory.reload.current_weight).to eq(13)
    end
  end

  context "with a malformed entry" do
    let(:loot_table) { ["not-an-object"] }

    it "records the failure without inventing a table award" do
      result = award_loot

      expect(result.awards.count(&:currency?)).to eq(1)
      expect(result.failures.map(&:message)).to contain_exactly(I18n.t("manage.loot_entry_object"))
      expect(npc_participation.reload.metadata.dig("loot_resolution", "failures")).to be_present
    end
  end

  context "with an entry that omits chance" do
    let(:loot_table) do
      [{"kind" => "item", "item_key" => "unresolved_probability", "quantity" => 1}]
    end

    it "records a configuration failure instead of inventing a guaranteed table drop" do
      result = award_loot

      expect(result.awards.count(&:currency?)).to eq(1)
      expect(result.failures.map(&:message)).to contain_exactly(I18n.t("manage.loot_chance_required"))
      expect(character.inventory.inventory_items).to be_empty
    end
  end

  context "when the recipient is not a match participant" do
    it "rejects the award before changing authoritative state" do
      player_participation.destroy!

      expect { award_loot }.to raise_error(
        described_class::InvalidParticipantError,
        I18n.t("arena.validations.loot_recipient_required")
      )
      expect(user.currency_wallet.reload.nv_balance).to eq(0)
      expect(npc_participation.reload.metadata).not_to have_key("loot_resolution")
    end
  end

  describe "luck scaling" do
    it "multiplies base drop chance by 1 + luck*0.01" do
      allow(character).to receive(:stats).and_return(
        Game::Systems::StatBlock.new(base: {luck: 100, dexterity: 1, strength: 1, vitality: 1, intelligence: 1})
      )
      awarder = described_class.new(
        match: arena_match,
        npc_participation:,
        character:,
        rng: Random.new(0)
      )

      expect(awarder.send(:luck_multiplier)).to eq(2.0)
      expect(awarder.send(:drop_chance_multiplier)).to be_within(0.01).of(2.0)
    end
  end
end
