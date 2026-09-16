# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProcessor, "combat benefits integration" do
  let(:now) { Time.utc(2026, 9, 11, 12) }
  let(:player) { create(:character, level: 17, current_hp: 100, max_hp: 100) }
  let(:match) { create(:arena_match, :live, metadata: {"source" => "world_npc", "is_npc_fight" => true}) }
  let!(:player_side) { create(:arena_participation, arena_match: match, character: player, user: player.user, team: "a") }
  let(:npc) { create(:npc_template, level: 17, metadata: npc_metadata) }
  let(:npc_metadata) { {"search_enabled" => true, "xp_reward" => 1_000_000, "loot_table" => loot_table} }
  let(:loot_table) { [] }
  let!(:npc_side) do
    create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b",
      metadata: {"current_hp" => 1, "max_hp" => 100})
  end
  let(:processor) { described_class.new(match, rng: Random.new(42)) }

  before do
    allow(Time).to receive(:current).and_return(now)
    create(:character_position, character: player)
    # Only damage is fixed; turn validation, loot, inventory, wallet, XP,
    # progression, completion markers and durable event publication are real.
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      {outcome: :hit, damage: args[:attacker_participation].npc? ? 0 : 100, critical: false}
    end
  end

  def grant(tier, expires_at: now + 60)
    player.update!(metadata: player.metadata.to_h.merge(
      "combat_entitlement" => {"tier" => tier, "expires_at" => expires_at.iso8601(6)}
    ))
  end

  def finish_fight
    result = processor.process_player_intent(player, :turn,
      target: npc_side, attacks: [{action_key: "simple", body_part: "torso"}],
      blocks: [{action_key: "torso_block", body_parts: ["torso"]}], expected_turn_number: 1)
    expect(result).to be_success
    expect(match.reload).to be_completed
  end

  describe "XP finalization" do
    {"standard" => 100_000, "premium" => 150_000, "gold" => 200_000, "vip" => 250_000, "worker" => 100_000}.each do |tier, cap|
      it "persists #{tier}'s capped maximum and never repeats XP on completion retry" do
        grant(tier)
        finish_fight

        expect(player.reload.experience).to eq(cap)
        expect(match.metadata.dig("rewards", "experience", "amount")).to eq(cap)
        expect(match.metadata["rewards_processed_at"]).to be_present
        expect(match.combat_log_entries.where(log_type: "system").pluck(:message)).to include("#{player.name} gains #{cap} experience.")

        allow(Time).to receive(:current).and_return(now + 120)
        expect(described_class.new(match).end_match("a")).to be(false)
        expect(player.reload.experience).to eq(cap)
        expect(player.metadata["npc_wins"]).to eq(1)
      end
    end

    it "leaves authored XP below the standard cap unchanged under VIP" do
      grant("vip")
      npc.update!(metadata: npc.metadata.merge("xp_reward" => 35))
      finish_fight
      expect(player.reload.experience).to eq(35)
    end

    it "applies the same cap to an explicit encounter total without multiplying earned XP" do
      grant("gold")
      match.update!(metadata: match.metadata.merge("encounter_experience_reward" => 160_000))
      finish_fight
      expect(player.reload.experience).to eq(160_000)
    end

    [-1, 0, 1].each do |seconds_before_expiry|
      it "evaluates expiry at XP finalization with #{seconds_before_expiry} seconds remaining" do
        grant("gold", expires_at: now + seconds_before_expiry)
        finish_fight
        expect(player.reload.experience).to eq(seconds_before_expiry.positive? ? 200_000 : 100_000)
      end
    end
  end

  describe "NPC search awards" do
    let(:item) { create(:item_template, :material, key: "combat_benefits_test_material", weight: 1, stack_limit: 99) }
    let(:loot_table) do
      [
        {"kind" => "item", "item_key" => item.key, "quantity" => 1, "chance" => 1.0},
        {"kind" => "currency", "currency" => "NV", "amount" => 24, "chance" => 1.0}
      ]
    end

    def expect_search(eligible:)
      if eligible
        expect(npc_side.reload.metadata.fetch("loot_resolution").fetch("failures")).to eq([])
      end
      expect(player.inventory.inventory_items.where(item_template: item).sum(:quantity)).to eq(eligible ? 1 : 0)
      transactions = player.user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot")
      expect(transactions.sum(:amount)).to eq(eligible ? 24 : 0)
      expect(transactions.count).to eq(eligible ? 1 : 0)
      expect(npc_side.reload.metadata.key?("loot_resolution")).to eq(eligible)
      expect(match.combat_log_entries.where(log_type: "loot").count).to eq(eligible ? 1 : 0)
      expect(GameEvent.where(recipient: player.user, event_type: [:item_found, :money_found]).count).to eq(eligible ? 2 : 0)
    end

    {"standard" => 2, "premium" => 2, "gold" => 4, "vip" => 6, "worker" => 2}.each do |tier, window|
      [-1, 1].each do |direction|
        [0, 1].each do |outside|
          difference = direction * (window + outside)
          it "#{outside.zero? ? 'awards' : 'rejects'} #{tier} search at level difference #{difference}" do
            grant(tier)
            npc.update!(level: player.level + difference)
            finish_fight
            expect_search(eligible: outside.zero?)
          end
        end
      end
    end

    [-1, 0, 1].each do |seconds_before_expiry|
      it "evaluates expiry before rolling loot with #{seconds_before_expiry} seconds remaining" do
        grant("gold", expires_at: now + seconds_before_expiry)
        npc.update!(level: 13)
        finish_fight
        expect_search(eligible: seconds_before_expiry.positive?)
      end
    end

    it "enforces the default standard window when search_enabled is absent" do
      npc.update!(level: 14, metadata: npc.metadata.except("search_enabled"))
      finish_fight
      expect_search(eligible: false)
    end

    it "honors explicit search disablement even for VIP at equal level" do
      grant("vip")
      npc.update!(metadata: npc.metadata.merge("search_enabled" => false))
      finish_fight
      expect_search(eligible: false)
    end

    [[2, 2, true], [2, 3, false], [0, 0, true], [0, 1, false]].each do |npc_cap, difference, eligible|
      it "preserves authored NPC limit #{npc_cap} for VIP at difference #{difference}" do
        grant("vip")
        npc.update!(level: player.level - difference, metadata: npc.metadata.merge("search_max_level_difference" => npc_cap))
        finish_fight
        expect_search(eligible: eligible)
      end
    end

    it "does not let a wider authored limit enlarge the active entitlement window" do
      npc.update!(level: 14, metadata: npc.metadata.merge("search_max_level_difference" => 6))
      finish_fight
      expect_search(eligible: false)
    end

    it "uses the actual sampled NPC level and its narrower snapshotted search limit" do
      grant("gold")
      npc.update!(level: 1)
      npc_side.update!(metadata: npc_side.metadata.merge("level" => 13, "search_max_level_difference" => 2))
      npc_side.snapshot_npc_combat_data!
      npc.update!(metadata: npc.metadata.merge("search_max_level_difference" => 6))
      finish_fight
      expect_search(eligible: false)
    end

    it "awards an eligible sampled member even when its template level is outside the window" do
      grant("gold")
      npc.update!(level: 1)
      npc_side.update!(metadata: npc_side.metadata.merge("level" => 13))
      finish_fight
      expect_search(eligible: true)
    end

    it "does not synthesize a drop when an eligible VIP opponent has no authored loot" do
      grant("vip")
      npc.update!(metadata: npc.metadata.except("loot_table"))
      finish_fight
      expect(player.inventory.inventory_items).to be_empty
      expect(player.user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot")).to be_empty
      expect(npc_side.reload.metadata.dig("loot_resolution", "awards")).to eq([])
      expect(match.combat_log_entries.where(log_type: "loot").sole.message).to include("nothing found")
    end

    it "preserves authored zero chance rather than adding a premium drop chance" do
      grant("vip")
      npc.update!(metadata: npc.metadata.merge("loot_table" => loot_table.map { |row| row.merge("chance" => 0.0) }))
      finish_fight
      expect(player.inventory.inventory_items).to be_empty
      expect(player.user.currency_wallet.currency_transactions.where(reason: "combat.npc_loot")).to be_empty
      expect(npc_side.reload.metadata.dig("loot_resolution", "awards")).to eq([])
    end

    it "does not duplicate item/NV awards or events when the defeat handler is retried" do
      grant("gold")
      npc.update!(level: 13)
      finish_fight
      expect_search(eligible: true)

      processor.send(:award_npc_loot!, npc_side.reload, player.reload)
      expect_search(eligible: true)
      expect(player_side.reload.metadata.fetch("loot_awards").size).to eq(2)
    end
  end
end
