# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arena::CombatProcessor, "committed exchanges" do
  let(:match) { create(:arena_match, status: :live, started_at: Time.current, current_turn_number: 1) }
  let(:player) { create(:character, current_hp: 100, max_hp: 100) }
  let!(:player_side) { create(:arena_participation, arena_match: match, character: player, user: player.user, team: "a") }
  let(:npc) { create(:npc_template) }
  let!(:npc_side) do
    create(:arena_participation, :npc, arena_match: match, npc_template: npc, team: "b",
      metadata: {"current_hp" => 65, "max_hp" => 65})
  end
  let(:processor) { described_class.new(match) }
  let(:turn) do
    {target: npc_side, attacks: [{action_key: "simple", body_part: "torso"}],
     blocks: [{action_key: "torso_block", body_parts: ["torso"]}], expected_turn_number: 1}
  end

  before do
    create(:character_position, character: player)
    decision = Arena::NpcCombatAi::Decision.new(action_type: :attack, target: player,
      params: {attacks: [{action_key: "simple", body_part: "torso"}, {action_key: "simple", body_part: "torso"}]})
    allow(Arena::NpcCombatAi).to receive(:new).and_return(instance_double(Arena::NpcCombatAi, decide_action: decision))
  end

  it "resolves both committed return strikes before defeat and completion after a lethal player hit" do
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      damage = args[:attacker_participation].npc? ? 3 : 1957
      {outcome: :hit, damage:, critical: false}
    end

    result = processor.process_player_intent(player, :turn, **turn)

    expect(result).to be_success
    expect(player.reload.current_hp).to eq(94)
    expect(npc_side.reload.current_hp).to eq(0)
    expect(match.reload).to be_completed
    expect(match.winning_team).to eq("a")
    expect(player_side.reload.metadata["damage_dealt"]).to eq(65)
    expect(player_side.metadata["raw_damage_dealt"]).to eq(1957)
    expect(player_side.metadata["opponents_defeated"]).to eq(1)
    expect(npc_side.metadata["damage_dealt"]).to eq(6)
    expect(npc_side.metadata["opponents_defeated"].to_i).to eq(0)
    entries = match.combat_log_entries.order(:sequence).to_a
    return_indices = entries.each_index.select { |index| entries[index].message.include?("hit #{player.name}") }
    defeat_index = entries.index { |entry| entry.log_type == "defeat" }
    expect(return_indices.size).to eq(2)
    expect(entries[return_indices.last].message).to include("for -3 [94/100]")
    expect(return_indices.max).to be < defeat_index

    expect { processor.process_player_intent(player, :turn, **turn) }.not_to change { match.combat_log_entries.count }
    expect(player.reload.current_hp).to eq(94)
  end

  it "records critical dodges in both directions without damage or defeat credit" do
    allow(processor).to receive(:resolve_physical_attack).and_return(
      {outcome: :dodge, damage: 0, critical: true}
    )

    expect(processor.process_player_intent(player, :turn, **turn)).to be_success
    expect(player.reload.current_hp).to eq(100)
    expect(npc_side.reload.current_hp).to eq(65)
    messages = match.combat_log_entries.where(log_type: "dodge").pluck(:message)
    expect(messages).to include("#{npc.name} dodged #{player.name}'s critical attack (torso)")
    expect(messages).to include("#{player.name} dodged #{npc.name}'s critical attack (torso)")
    expect(player_side.reload.metadata["opponents_defeated"].to_i).to eq(0)
    expect(player_side.metadata["damage_dealt"].to_i).to eq(0)
  end

  it "retains shield coverage for every strike in the exchange and clears it before the next turn" do
    blocks = []
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      if args[:attacker_participation].npc?
        blocks << args[:block]
        {outcome: :blocked, damage: 0, critical: false}
      else
        {outcome: :hit, damage: 1, critical: false}
      end
    end

    expect(processor.process_player_intent(player, :turn, **turn)).to be_success
    expect(blocks.size).to eq(2)
    expect(blocks).to all(include("body_parts" => ["torso"]))
    expect(player.reload.current_hp).to eq(100)
    expect(player.metadata["blocking"]).to be_falsey
    expect(match.reload.current_turn_number).to eq(2)
    expect(processor.process_player_intent(player, :turn, **turn).error).to include("Fight state changed")
  end

  it "resolves only the selected NPC's return package in a multi-opponent fight" do
    other_npc = create(:npc_template, name: "Other skeleton", level: 7)
    other_side = create(:arena_participation, :npc, arena_match: match, npc_template: other_npc, team: "b")
    attackers = []
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      attackers << args[:attacker_participation].id
      {outcome: :hit, damage: 1, critical: false}
    end

    expect(processor.process_player_intent(player, :turn, **turn)).to be_success
    expect(attackers).to eq([player_side.id, npc_side.id, npc_side.id])
    expect(attackers).not_to include(other_side.id)
    expect(other_side.reload.metadata["damage_dealt"]).to be_nil
  end

  it "counts defeated opponents separately from damaging hits and ignores post-lethal overkill in totals" do
    player_side.update!(metadata: {"combat_profile" => {"ap_limit" => 200, "physical_attack_cost_seed" => 62}})
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      {outcome: :hit, damage: args[:attacker_participation].npc? ? 0 : 40, critical: false}
    end
    expect(processor.process_player_intent(player, :turn, **turn)).to be_success
    expect(player_side.reload.metadata).to include("damage_dealt" => 40, "raw_damage_dealt" => 40, "damage_hits" => 1)
    expect(player_side.metadata["opponents_defeated"].to_i).to eq(0)

    attacks = [{action_key: "simple", body_part: "head"}, {action_key: "simple", body_part: "torso"}]
    expect(processor.process_player_intent(player, :turn, **turn.merge(attacks:, blocks: [], expected_turn_number: 2))).to be_success
    expect(player_side.reload.metadata).to include("damage_dealt" => 65, "raw_damage_dealt" => 80, "damage_hits" => 2, "opponents_defeated" => 1)
    expect(match.reload).to be_completed
  end

  it "logs later committed hits on a defeated target without awarding additional credited damage" do
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      {outcome: :hit, damage: args[:attacker_participation].npc? ? 0 : 1200, critical: false}
    end
    attacks = [{action_key: "simple", body_part: "torso"}, {action_key: "simple", body_part: "stomach"}]
    player_side.update!(metadata: {"combat_profile" => {"ap_limit" => 200, "physical_attack_cost_seed" => 62}})

    result = processor.process_player_intent(player, :turn, **turn.merge(attacks:, blocks: []))

    expect(result).to be_success
    expect(result[:attacks].size).to eq(2)
    expect(player_side.reload.metadata).to include("damage_dealt" => 65, "damage_hits" => 1)
    expect(match.combat_log_entries.where(log_type: "damage").select { |entry| entry.message.include?("for -1200 [0/65]") }.size).to eq(2)
    expect(match.reload).to be_completed
  end

  it "prepares an NPC block before player strikes and keeps it for the whole package" do
    decision = Arena::NpcCombatAi::Decision.new(action_type: :attack, target: player,
      params: {block_key: "torso_block", attacks: [{action_key: "simple", body_part: "torso"}]})
    allow(Arena::NpcCombatAi).to receive(:new).and_return(instance_double(Arena::NpcCombatAi, decide_action: decision))
    player_side.update!(metadata: {"combat_profile" => {"ap_limit" => 200}})
    incoming_blocks = []
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      incoming_blocks << args[:block] unless args[:attacker_participation].npc?
      {outcome: :blocked, damage: 0, critical: false}
    end
    attacks = Array.new(2) { {action_key: "simple", body_part: "torso"} }

    expect(processor.process_player_intent(player, :turn, **turn.merge(attacks:, blocks: []))).to be_success
    expect(incoming_blocks).to all(include("body_parts" => ["torso"]))
    expect(incoming_blocks.size).to eq(2)
    expect(npc_side.reload.metadata["blocking"]).to be_falsey
  end

  it "resolves selected NPC commitments on both mixed player/NPC sides through the same round" do
    opponent = create(:character, current_hp: 100, max_hp: 100)
    create(:character_position, character: opponent)
    opponent_side = create(:arena_participation, arena_match: match, character: opponent, user: opponent.user, team: "b")
    allied_npc = create(:arena_participation, :npc, arena_match: match, team: "a",
      metadata: {"current_hp" => 65, "max_hp" => 65})
    allow(Arena::NpcCombatAi).to receive(:new) do |**_args|
      decision = Arena::NpcCombatAi::Decision.new(action_type: :attack,
        params: {attacks: [{action_key: "simple", body_part: "torso"}]})
      instance_double(Arena::NpcCombatAi, decide_action: decision)
    end
    resolved = []
    player_damage = 100
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      resolved << [args[:attacker_participation].id, args[:defender_participation].id]
      {outcome: :hit, damage: args[:attacker_participation].npc? ? 3 : player_damage, critical: false}
    end

    expect(processor.process_player_intent(player, :turn, **turn)[:waiting]).to be true
    expect(processor.process_player_intent(opponent, :turn, **turn.merge(target: allied_npc))[:resolved]).to be true
    expect(resolved).to eq([[player_side.id, npc_side.id], [opponent_side.id, allied_npc.id], [npc_side.id, player_side.id], [allied_npc.id, opponent_side.id]])
    expect([player.reload.current_hp, opponent.reload.current_hp]).to eq([97, 97])
    expect([npc_side.reload.current_hp, allied_npc.reload.current_hp]).to eq([0, 0])
    expect(match.reload).to be_live
    expect(match.current_turn_number).to eq(2)

    resolved.clear
    player_damage = 1
    expect(processor.process_player_intent(player, :turn, **turn.merge(target: opponent, expected_turn_number: 2))[:waiting]).to be true
    expect(processor.process_player_intent(opponent, :turn, **turn.merge(target: player, expected_turn_number: 2))[:resolved]).to be true
    expect(resolved).to eq([[player_side.id, opponent_side.id], [opponent_side.id, player_side.id]])
    expect([npc_side.reload.metadata["damage_dealt"], allied_npc.reload.metadata["damage_dealt"]]).to eq([3, 3])
    expect(match.reload.current_turn_number).to eq(3)
  end

  context "when a player and an NPC strike the same character" do
    let(:opponent) { create(:character, current_hp: 100, max_hp: 100) }
    let!(:opponent_side) do
      create(:arena_participation, arena_match: match, character: opponent, user: opponent.user, team: "b")
    end
    let(:opponent_damage) { 40 }
    let(:opponent_critical) { false }

    before do
      create(:character_position, character: opponent)
      armor = create(:item_template, :armor, stat_modifiers: {"hp" => 50})
      create(:inventory_item, :equipped, inventory: player.inventory, item_template: armor)
      allow(processor).to receive(:resolve_physical_attack) do |**args|
        attacker = args.fetch(:attacker_participation)
        damage = if attacker.npc?
          3
        elsif attacker.character_id == opponent.id
          opponent_damage
        else
          1
        end
        {outcome: :hit, damage:, critical: attacker.character_id == opponent.id && opponent_critical}
      end
    end

    def resolve_mixed_round
      expect(processor.process_player_intent(player, :turn, **turn)[:waiting]).to be true
      expect(processor.process_player_intent(opponent, :turn, **turn.merge(target: player))[:resolved]).to be true
    end

    it "accumulates player damage and each NPC strike using current HP and logs effective maxima" do
      resolve_mixed_round

      expect(player.reload.current_hp).to eq(54)
      expect(player.max_hp).to eq(100)
      expect(player.effective_max_hp).to eq(150)
      expect(player_side.reload.metadata["damage_taken"]).to eq(46)
      expect(opponent_side.reload.metadata).to include("damage_dealt" => 40, "raw_damage_dealt" => 40)
      expect(npc_side.reload.metadata).to include("damage_dealt" => 6, "raw_damage_dealt" => 6)
      expect(npc_side.metadata["opponents_defeated"].to_i).to eq(0)
      messages = match.combat_log_entries.where(log_type: "damage").order(:sequence).pluck(:message)
      expect(messages).to include("#{opponent.name} hit #{player.name} (torso) for -40 [60/150]")
      expect(messages.last(2)).to eq([
        "#{npc.name} hit #{player.name} (torso) for -3 [57/150]",
        "#{npc.name} hit #{player.name} (torso) for -3 [54/150]"
      ])
      expect(match.reload).to be_live
      expect(match.current_turn_number).to eq(2)
    end

    context "when the first NPC return is lethal" do
      let(:opponent_damage) { 99 }

      it "credits the last HP and one defeat while retaining both committed return logs" do
        resolve_mixed_round

        expect(player.reload.current_hp).to eq(0)
        expect(player_side.reload).to be_defeat
        expect(player_side.metadata["damage_taken"]).to eq(100)
        expect(opponent_side.reload.metadata["damage_dealt"]).to eq(99)
        expect(opponent_side.metadata["opponents_defeated"].to_i).to eq(0)
        expect(npc_side.reload.metadata).to include("damage_dealt" => 1, "raw_damage_dealt" => 3, "opponents_defeated" => 1)
        messages = match.combat_log_entries.where(log_type: "damage").order(:sequence).pluck(:message)
        expect(messages.last(2)).to eq(Array.new(2, "#{npc.name} hit #{player.name} (torso) for -3 [0/150]"))
        expect(match.combat_log_entries.where(log_type: "defeat").sole.message).to eq("#{player.name} has been defeated!")
        expect(match.reload).to be_completed
        expect(match.winning_team).to eq("b")
      end
    end

    context "when the player strike already defeated the target" do
      let(:opponent_damage) { 120 }
      let(:opponent_critical) { true }

      it "logs committed NPC overkill without reviving the target or adding damage or defeat credit" do
        resolve_mixed_round

        expect(player.reload.current_hp).to eq(0)
        expect(player_side.reload).to be_defeat
        expect(player_side.metadata["damage_taken"]).to eq(100)
        expect(opponent_side.reload.metadata).to include("damage_dealt" => 100, "raw_damage_dealt" => 120, "opponents_defeated" => 1)
        expect(npc_side.reload.metadata.values_at("damage_dealt", "raw_damage_dealt", "opponents_defeated").map(&:to_i)).to eq([0, 0, 0])
        entries = match.combat_log_entries.order(:sequence).to_a
        expect(entries.find { |entry| entry.log_type == "critical" }.message).to eq(
          "#{opponent.name} critical hit (torso) #{player.name} for -120 [0/150]"
        )
        npc_hits = entries.select { |entry| entry.message == "#{npc.name} hit #{player.name} (torso) for -3 [0/150]" }
        expect(npc_hits.size).to eq(2)
        defeats = entries.select { |entry| entry.log_type == "defeat" }
        expect(defeats.size).to eq(1)
        expect(npc_hits.last.sequence).to be < defeats.first.sequence
        expect(match.reload).to be_completed
        expect(match.winning_team).to eq("b")

        expect { processor.process_player_intent(opponent, :turn, **turn.merge(target: player)) }
          .not_to change { match.combat_log_entries.count }
        expect(player.reload.current_hp).to eq(0)
      end
    end
  end

  it "prepares a configured NPC defend decision before incoming strikes and clears it after the turn" do
    allow(Arena::NpcCombatAi).to receive(:new).and_call_original
    npc.update!(metadata: npc.metadata.to_h.merge("defend_hp_below" => 1.0, "defend_chance" => 1.0))
    npc_side.update!(metadata: {"current_hp" => 50, "max_hp" => 65})
    player_side.update!(metadata: {"combat_profile" => {"ap_limit" => 200}})
    allow(processor.rng).to receive(:rand).and_call_original
    allow(processor.rng).to receive(:rand).with(100).and_return(0, 99, 0, 0, 99, 0)
    attacks = Array.new(2) { {action_key: "simple", body_part: "torso"} }

    result = processor.process_player_intent(player, :turn, **turn.merge(attacks:, blocks: []))

    expect(result).to be_success
    expect(result[:attacks]).to all(include(outcome: :blocked, block_key: "torso_block"))
    expect(result[:attacks].size).to eq(2)
    expect(npc_side.reload.current_hp).to eq(50)
    expect(npc_side.metadata["blocking"]).to be_falsey
    expect(player.reload.current_hp).to eq(100)
    entries = match.combat_log_entries.order(:sequence).to_a
    stance = entries.select { |entry| entry.message == "#{npc.name} takes a defensive stance" }
    expect(stance.size).to eq(1)
    expect(entries.count { |entry| entry.log_type == "block" }).to eq(2)
    expect(stance.first.sequence).to be < entries.find { |entry| entry.log_type == "block" }.sequence
    expect(match.reload.current_turn_number).to eq(2)
  end

  it "does not invent a search result for an ineligible low-level or hunter NPC" do
    npc.update!(level: 3, metadata: {"search_max_level_difference" => 2})
    player.update!(level: 17)
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      {outcome: :hit, damage: args[:attacker_participation].npc? ? 0 : 100, critical: false}
    end
    expect(processor.process_player_intent(player, :turn, **turn)).to be_success
    expect(match.combat_log_entries.where(log_type: "loot")).to be_empty
    expect(npc_side.reload.metadata["loot_processed_at"]).to be_nil
  end

  it "uses the same lethal return rule for two player commitments" do
    npc_side.destroy!
    opponent = create(:character, current_hp: 65, max_hp: 65)
    create(:character_position, character: opponent)
    opponent_side = create(:arena_participation, arena_match: match, character: opponent, user: opponent.user, team: "b")
    allow(processor).to receive(:resolve_physical_attack) do |**args|
      damage = args[:attacker_participation].character_id == player.id ? 100 : 7
      {outcome: :hit, damage:, critical: false}
    end

    first = processor.process_player_intent(player, :turn, **turn.merge(target: opponent))
    expect(first[:waiting]).to be true
    second = processor.process_player_intent(opponent, :turn, **turn.merge(target: player))

    expect(second[:resolved]).to be true
    expect(player.reload.current_hp).to eq(93)
    expect(opponent.reload.current_hp).to eq(0)
    expect(opponent_side.reload).to be_defeat
    expect(match.reload).to be_completed
    expect(player_side.reload.metadata["damage_dealt"]).to eq(65)
    expect(opponent_side.metadata["damage_dealt"]).to eq(7)
  end
end
