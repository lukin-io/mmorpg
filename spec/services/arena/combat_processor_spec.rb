# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProcessor do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:character1) { create(:character, user: user1, level: 10, current_hp: 100, max_hp: 100) }
  let(:character2) { create(:character, user: user2, level: 10, current_hp: 100, max_hp: 100) }
  let!(:arena_room) do
    create(:arena_room,
      name: "Test Arena",
      level_min: 1,
      level_max: 100,
      active: true)
  end
  let!(:arena_match) do
    create(:arena_match,
      arena_room: arena_room,
      status: :live,
      match_type: :duel,
      started_at: Time.current)
  end

  let!(:participation1) do
    create(:arena_participation,
      arena_match: arena_match,
      character: character1,
      user: user1,
      team: "a")
  end

  let!(:participation2) do
    create(:arena_participation,
      arena_match: arena_match,
      character: character2,
      user: user2,
      team: "b")
  end

  let(:character1_ap_limit) { character1.max_action_points }
  let(:character2_ap_limit) { character2.max_action_points }
  let(:processor) { described_class.new(arena_match) }

  before do
    create(:character_position, character: character1)
    create(:character_position, character: character2)
  end

  describe "#process_action" do
    context "with attack action" do
      it "deals damage to target" do
        initial_hp = character2.current_hp

        result = processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        # The resolver can block, miss, dodge, or land a zero-damage hit.
        expect(result.success?).to be true
        if result[:damage].to_i.positive?
          expect(character2.reload.current_hp).to be < initial_hp
        else
          expect(character2.reload.current_hp).to eq(initial_hp)
        end
      end

      it "returns damage data" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        expect(result[:damage]).to be_a(Integer)
        expect(result[:damage]).to be >= 0
      end

      it "broadcasts combat action" do
        # Allow for either attack or blocked broadcast
        allow(processor.broadcaster).to receive(:broadcast_combat_action)

        processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        expect(processor.broadcaster).to have_received(:broadcast_combat_action)
          .with(character1, anything, anything, kind_of(Integer), hash_including(:body_part))
      end

      it "persists durable fight log entries" do
        expect {
          processor.process_action(
            character1,
            :attack,
            target: character2,
            attack_type: :simple,
            body_part: "torso"
          )
        }.to change { arena_match.combat_log_entries.count }.by_at_least(1)

        entry = arena_match.combat_log_entries.last
        expect(entry.arena_match).to eq(arena_match)
        expect(entry.tags).to include("arena")
        expect(arena_match.reload.metadata).not_to have_key("combat_log")
      end
    end

    context "with defend action" do
      it "sets defending state with block parts" do
        result = processor.process_action(
          character1,
          :defend,
          block_parts: ["torso"]
        )

        expect(result.success?).to be true
        expect(result[:defending]).to be true
        expect(result[:block_parts]).to eq(["torso"])
      end
    end

    context "when match is not live" do
      before do
        arena_match.update!(status: :completed)
      end

      it "returns failure" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Бой не активен")
      end
    end

    context "when character is not in match" do
      let(:non_participant) { create(:character, level: 10) }

      before do
        create(:character_position, character: non_participant)
      end

      it "returns failure" do
        result = processor.process_action(
          non_participant,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Персонаж не участвует в этом бою")
      end
    end

    context "when character is dead" do
      before do
        character1.update!(current_hp: 0)
      end

      it "returns failure" do
        result = processor.process_action(
          character1,
          :attack,
          target: character2
        )

        expect(result.success?).to be false
        expect(result.error).to eq("Персонаж повержен")
      end
    end
  end

  describe "#should_end?" do
    it "returns false when both teams have living members" do
      expect(processor.should_end?).to be false
    end

    it "returns true when one team is eliminated" do
      character2.update!(current_hp: 0)

      expect(processor.should_end?).to be true
    end
  end

  describe "#determine_winner" do
    it "returns team with living members" do
      character2.update!(current_hp: 0)

      expect(processor.determine_winner).to eq("a")
    end

    it "returns team with higher HP when both alive" do
      character1.update!(current_hp: 80)
      character2.update!(current_hp: 50)

      expect(processor.determine_winner).to eq("a")
    end

    it "returns nil for draw" do
      character1.update!(current_hp: 50)
      character2.update!(current_hp: 50)

      expect(processor.determine_winner).to be_nil
    end
  end

  describe "#end_match" do
    it "updates match status to completed" do
      processor.end_match("a")

      expect(arena_match.reload.status).to eq("completed")
      expect(arena_match.ended_at).to be_present
      expect(arena_match.winning_team).to eq("a")
    end

    it "finalizes participations" do
      processor.end_match("a")

      expect(participation1.reload.result).to eq("victory")
      expect(participation2.reload.result).to eq("defeat")
    end

    it "broadcasts match ended" do
      expect(processor.broadcaster).to receive(:broadcast_match_ended).with("a", reason: :normal)

      processor.end_match("a")
    end
  end

  describe "NPC fight capture behavior" do
    let(:npc_template) do
      create(:npc_template,
        role: "arena_bot",
        name: "Манекен",
        level: 5,
        metadata: {
          "base_damage" => 15,
          "ai_behavior" => "passive",
          "loot_table" => [
            {"item_key" => "wood_chips", "item_name" => "Щепки", "chance" => 1.0, "quantity" => 1}
          ]
        })
    end

    let!(:wood_chips) do
      create(:item_template,
        :material,
        key: "wood_chips",
        name: "Щепки",
        weight: 1,
        stack_limit: 99)
    end

    let(:npc_match) do
      create(:arena_match,
        arena_room: arena_room,
        status: :live,
        match_type: :duel,
        started_at: Time.current,
        metadata: {
          "is_npc_fight" => true,
          "combat_profile" => {
            "ap_limit" => 140,
            "physical_attack_cost_seed" => 67,
            "simple_attack_cost" => 67,
            "aimed_attack_cost" => 87,
            "max_magic_mana" => 52,
            "block_table" => "normal"
          }
        })
    end

    let!(:npc_player_participation) do
      create(:arena_participation,
        arena_match: npc_match,
        character: character1,
        user: user1,
        team: "a")
    end

    let!(:npc_participation) do
      create(:arena_participation, :npc,
        arena_match: npc_match,
        npc_template: npc_template,
        team: "b",
        metadata: {"current_hp" => 105, "max_hp" => 105})
    end

    def deterministic_arena_processor(match, *rolls)
      rng = instance_double(Random)
      allow(rng).to receive(:rand) do |range_or_limit = nil|
        value = rolls.shift || 99
        range_or_limit.is_a?(Range) ? value.clamp(range_or_limit.min, range_or_limit.max) : value
      end
      described_class.new(match, rng:)
    end

    it "processes a captured-style NPC response with multiple physical attacks" do
      captured_processor = deterministic_arena_processor(npc_match, 0, 99, 99, 3, 0, 99, 99, 3)
      allow(captured_processor.broadcaster).to receive(:broadcast_vitals_update)
      allow(captured_processor.broadcaster).to receive(:broadcast_combat_action)

      decision = Arena::NpcCombatAi::Decision.new(
        action_type: :attack,
        target: character1,
        params: {
          body_part: "stomach",
          attack_type: "simple",
          attacks: [
            {action_key: "simple", body_part: "stomach"},
            {action_key: "simple", body_part: "legs"}
          ]
        }
      )
      allow(Arena::NpcCombatAi).to receive(:new).and_return(instance_double(Arena::NpcCombatAi, decide_action: decision))

      result = captured_processor.process_npc_turn

      expect(result).to be_success
      expect(result[:attacks].size).to eq(2)
      damage_entries = npc_match.reload.combat_log_entries.select { |entry| entry.log_type == "damage" && entry.message.include?("Манекен attacks") }
      expect(damage_entries.map(&:message).join(" ")).to include("stomach", "legs")
    end

    it "logs the automatic loot check after an NPC defeat" do
      npc_participation.update!(metadata: {"current_hp" => 1, "max_hp" => 105})
      captured_processor = deterministic_arena_processor(npc_match, 0, 99, 99, 5)
      allow(captured_processor.broadcaster).to receive(:broadcast_ap_update)
      allow(captured_processor.broadcaster).to receive(:broadcast_vitals_update)
      allow(captured_processor.broadcaster).to receive(:broadcast_combat_action)
      allow(captured_processor.broadcaster).to receive(:broadcast_match_ended)

      result = captured_processor.process_action(
        character1,
        :attack,
        target: npc_participation,
        attack_type: :simple,
        body_part: "torso"
      )

      expect(result).to be_success
      log_entries = npc_match.reload.combat_log_entries
      expect(log_entries.map(&:log_type)).to include("defeat", "loot", "victory")
      loot_entry = log_entries.find { |entry| entry.log_type == "loot" }
      expect(loot_entry.message).to include("searched Манекен")
      expect(loot_entry.message).to include("Вещь «Щепки»")
      expect(character1.inventory.inventory_items.find_by(item_template: wood_chips).quantity).to eq(1)
      expect(npc_player_participation.reload.metadata["loot_drops"].last).to include(
        "item_key" => "wood_chips",
        "item_name" => "Щепки",
        "quantity" => 1
      )
    end
  end

  describe "AP (Action Points) system" do
    describe "#process_action with AP" do
      it "deducts AP for simple attack from the participant AP budget" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)

        processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )

        expect(participation1.reload.metadata["current_ap"]).to eq(character1_ap_limit - 45)
      end

      it "deducts AP for aimed attack from the participant AP budget" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)

        processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :aimed,
          body_part: "head"
        )

        expect(participation1.reload.metadata["current_ap"]).to eq(character1_ap_limit - 65)
      end

      it "deducts AP for defend action (30 AP)" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)

        processor.process_action(
          character1,
          :defend,
          block_parts: ["torso"]
        )

        expect(participation1.reload.metadata["current_ap"]).to eq(character1_ap_limit - 30)
      end

      it "fails when not enough AP" do
        # Set AP to low value
        participation1.update!(metadata: {"current_ap" => 20})

        result = processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple
        )

        expect(result.success?).to be false
        expect(result.error).to include("Недостаточно ОД")
      end

      it "processes a Neverlands-style turn package with attack and block" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)
        allow(processor.broadcaster).to receive(:broadcast_system_message)

        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(result.success?).to be true
        expect(result[:waiting]).to be true
        expect(result[:resolved]).to be false
        expect(result[:total_ap]).to eq(75)
        expect(participation1.reload.metadata["current_ap"]).to eq(character1_ap_limit - 75)
        expect(participation1.metadata["pending_turn"]).to be_present
        expect(character1.reload.metadata["blocked_parts"]).to be_blank
      end

      it "rejects a single plain attack turn without a block or action slot" do
        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}]
        )

        expect(result.success?).to be false
        expect(result.error).to include("valid attack")
      end

      it "allows a single mana attack such as Spirit Arrow from the captured selector" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)
        allow(processor.broadcaster).to receive(:broadcast_system_message)

        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "spirit_arrow", body_part: "torso"}]
        )

        expect(result.success?).to be true
        expect(result[:waiting]).to be true
      end

      it "waits for both players before resolving the committed round" do
        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)
        allow(processor.broadcaster).to receive(:broadcast_system_message)

        first = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(first.success?).to be true
        expect(first[:waiting]).to be true
        expect(character2.reload.current_hp).to eq(100)

        second = processor.process_action(
          character2,
          :turn,
          target: character1,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(second.success?).to be true
        expect(second[:waiting]).to be false
        expect(second[:resolved]).to be true
        expect(participation1.reload.metadata["pending_turn"]).to be_blank
        expect(participation2.reload.metadata["pending_turn"]).to be_blank
        expect(participation1.metadata["current_ap"]).to eq(character1_ap_limit)
        expect(participation2.metadata["current_ap"]).to eq(character2_ap_limit)
      end

      it "uses captured Neverlands fight profile values when present" do
        participation1.update!(
          metadata: {
            "combat_profile" => {
              "ap_limit" => 140,
              "physical_attack_cost_seed" => 67,
              "simple_attack_cost" => 67,
              "aimed_attack_cost" => 87,
              "max_magic_mana" => 52,
              "block_table" => "normal"
            }
          }
        )

        allow(processor.broadcaster).to receive(:broadcast_ap_update)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)
        allow(processor.broadcaster).to receive(:broadcast_system_message)

        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(result.success?).to be true
        expect(result[:total_ap]).to eq(97)
        expect(participation1.reload.metadata["current_ap"]).to eq(43)
        expect(participation1.metadata.dig("pending_turn", "ap_limit")).to eq(140)
      end

      it "validates a captured-profile live player round and resolves only after both turns arrive" do
        captured_profile = {
          "ap_limit" => 140,
          "physical_attack_cost_seed" => 67,
          "simple_attack_cost" => 67,
          "aimed_attack_cost" => 87,
          "max_magic_mana" => 52,
          "block_table" => "normal"
        }
        participation1.update!(metadata: {"combat_profile" => captured_profile})
        participation2.update!(metadata: {"combat_profile" => captured_profile})

        rng = instance_double(Random)
        allow(rng).to receive(:rand).with(100).and_return(0, 99, 0, 99)
        captured_processor = described_class.new(arena_match, rng:)

        allow(captured_processor.broadcaster).to receive(:broadcast_ap_update)
        allow(captured_processor.broadcaster).to receive(:broadcast_combat_action)
        allow(captured_processor.broadcaster).to receive(:broadcast_vitals_update)
        allow(captured_processor.broadcaster).to receive(:broadcast_system_message)

        first = captured_processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )
        second = captured_processor.process_action(
          character2,
          :turn,
          target: character1,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(first).to be_success
        expect(first[:total_ap]).to eq(97)
        expect(first[:waiting]).to be true
        expect(second).to be_success
        expect(second[:resolved]).to be true
        expect(participation1.reload.metadata["current_ap"]).to eq(140)
        expect(participation2.reload.metadata["current_ap"]).to eq(140)
        expect(arena_match.reload.combat_log_entries.map(&:log_type)).to include("block")
      end

      it "keeps team/player fights in the player turn-commit flow even when an NPC is present" do
        npc_template = create(:npc_template, name: "Observer Bot", npc_key: "observer_bot")
        create(:arena_participation,
          :npc,
          arena_match: arena_match,
          npc_template: npc_template,
          team: "b")

        expect(Arena::NpcCombatAi).not_to receive(:new)

        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [{action_key: "simple", body_part: "torso"}],
          blocks: [{action_key: "torso_block", body_parts: ["torso"]}]
        )

        expect(result).to be_success
        expect(result[:waiting]).to be true
        expect(participation1.reload.metadata["pending_turn"]).to be_present
      end

      it "rejects uncaptured magic/action slots" do
        errors = processor.send(
          :validate_turn_actions,
          [],
          [],
          [{key: "unknown_action"}],
          actor: character1
        )

        expect(errors).to include("Invalid magic/action slot 1: unknown_action")
      end

      it "rejects captured magic blocks above the fight mana ceiling" do
        character1.update!(current_mp: 200, max_mp: 200)
        participation1.update!(
          metadata: {
            "combat_profile" => {
              "ap_limit" => 200,
              "physical_attack_cost_seed" => 67,
              "max_magic_mana" => 52
            }
          }
        )

        errors = processor.send(
          :validate_turn_mana,
          character1,
          [],
          [{action_key: "crystal_sphere", body_parts: %w[head torso stomach legs]}],
          []
        )

        expect(errors).to include("Magic/action mana exceeds fight limit (65/52)")
      end

      it "lets a waiting player claim victory after the turn timer expires" do
        arena_match.update!(current_turn_started_at: 6.minutes.ago, turn_timeout_seconds: 300)

        allow(processor.broadcaster).to receive(:broadcast_match_ended)

        participation1.metadata ||= {}
        participation1.metadata["pending_turn"] = {
          "turn_number" => arena_match.current_turn_number || 1,
          "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
          "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}],
          "skills" => [],
          "total_ap" => 75
        }
        participation1.save!

        result = processor.claim_timeout(character1, mode: "victory")

        expect(result.success?).to be true
        expect(result[:mode]).to eq("victory")
        expect(arena_match.reload).to be_completed
        expect(arena_match.winning_team).to eq(participation1.team)
        expect(participation1.reload.result).to eq("victory")
        expect(participation2.reload.result).to eq("defeat")
      end

      it "records a draw when a waiting player accepts timeout draw" do
        arena_match.update!(current_turn_started_at: 6.minutes.ago, turn_timeout_seconds: 300)

        allow(processor.broadcaster).to receive(:broadcast_match_ended)

        participation1.metadata ||= {}
        participation1.metadata["pending_turn"] = {
          "turn_number" => arena_match.current_turn_number || 1,
          "attacks" => [{"action_key" => "simple", "body_part" => "torso"}],
          "blocks" => [{"action_key" => "torso_block", "body_parts" => ["torso"]}],
          "skills" => [],
          "total_ap" => 75
        }
        participation1.save!

        result = processor.claim_timeout(character1, mode: "draw")

        expect(result.success?).to be true
        expect(result[:mode]).to eq("draw")
        expect(arena_match.reload).to be_completed
        expect(arena_match.winning_team).to be_nil
        expect(participation1.reload.result).to eq("draw")
        expect(participation2.reload.result).to eq("draw")
      end

      it "rejects a turn package that exceeds the dynamic AP budget" do
        result = processor.process_action(
          character1,
          :turn,
          target: character2,
          attacks: [
            {action_key: "aimed", body_part: "head"},
            {action_key: "aimed", body_part: "torso"}
          ],
          blocks: []
        )

        expect(result.success?).to be false
        expect(result.error).to include("Actions exceed AP limit")
        expect(result.error).to include("155/#{character1_ap_limit}")
      end

      it "broadcasts AP update after action" do
        expect(processor.broadcaster).to receive(:broadcast_ap_update)
          .with(character1, character1_ap_limit - 45, character1_ap_limit)
        allow(processor.broadcaster).to receive(:broadcast_combat_action)
        allow(processor.broadcaster).to receive(:broadcast_vitals_update)

        processor.process_action(
          character1,
          :attack,
          target: character2,
          attack_type: :simple,
          body_part: "torso"
        )
      end
    end

    describe "AP constants" do
      it "defines AP_PER_TURN as 80" do
        expect(described_class::AP_PER_TURN).to eq(80)
      end

      it "defines BLOCK_AP_COST as 30" do
        expect(described_class::BLOCK_AP_COST).to eq(30)
      end

      it "defines simple attack AP cost as 45" do
        expect(Game::Combat::ActionCatalog.attack_cost(:simple)).to eq(45)
      end

      it "defines aimed attack AP cost as 65" do
        expect(Game::Combat::ActionCatalog.attack_cost(:aimed)).to eq(65)
      end
    end
  end

  describe "Body part damage multipliers" do
    it "defines head multiplier as 1.3" do
      expect(described_class::BODY_PART_MULTIPLIERS["head"]).to eq(1.3)
    end

    it "defines torso multiplier as 1.0" do
      expect(described_class::BODY_PART_MULTIPLIERS["torso"]).to eq(1.0)
    end

    it "defines stomach multiplier as 1.1" do
      expect(described_class::BODY_PART_MULTIPLIERS["stomach"]).to eq(1.1)
    end

    it "defines legs multiplier as 0.9" do
      expect(described_class::BODY_PART_MULTIPLIERS["legs"]).to eq(0.9)
    end
  end

  describe "Attack types" do
    it "defines simple attack with damage_mult 1.0" do
      expect(Game::Combat::ActionCatalog.attack_damage_multiplier(:simple)).to eq(1.0)
    end

    it "defines aimed attack with damage_mult 1.2" do
      expect(Game::Combat::ActionCatalog.attack_damage_multiplier(:aimed)).to eq(1.2)
    end

    it "defines aimed attack with hit_bonus 15" do
      expect(Game::Combat::ActionCatalog.attack_hit_bonus(:aimed)).to eq(15)
    end
  end

  describe "trauma/risk value" do
    it "does not invent HP or XP penalties before Neverlands formula capture" do
      arena_match.update!(trauma_percent: 30)
      character1.update!(current_hp: 80, experience: 1000)
      character2.update!(current_hp: 0, experience: 1000)

      processor.end_match("a")

      expect(character1.reload.current_hp).to eq(80)
      expect(character1.experience).to eq(1000)
      expect(character2.reload.experience).to eq(1000)
    end
  end
end
