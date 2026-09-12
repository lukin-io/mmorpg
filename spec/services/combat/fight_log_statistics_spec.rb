# frozen_string_literal: true

require "rails_helper"

RSpec.describe Combat::FightLogStatistics do
  subject(:statistics) { described_class.new(match) }

  let(:character) { create(:character, current_hp: 0) }
  let(:match) do
    create(:arena_match, :completed, winning_team: "b", metadata: {
      "rewards" => {"experience" => {"character_id" => character.id, "amount" => 57}}
    })
  end
  let!(:player) do
    create(:arena_participation, :defeat, arena_match: match, character: character, user: character.user,
      team: "a", metadata: {"damage_dealt" => 605, "raw_damage_dealt" => 686, "damage_hits" => 1, "opponents_defeated" => 1})
  end
  let!(:npc) do
    create(:arena_participation, :npc, :defeat, arena_match: match, team: "b",
      metadata: {"current_hp" => 0, "max_hp" => 605, "damage_dealt" => 0, "opponents_defeated" => 0})
  end

  def log_damage(actor, amount, target: npc, **attributes)
    create(:combat_log_entry, arena_match: match, actor: actor, target: target,
      log_type: "critical", damage_amount: amount, body_part: "torso", tags: %w[damage torso], **attributes)
  end

  it "uses credited HP and the actual losing reward recipient despite lethal overkill and post-lethal events" do
    log_damage(player, 686)
    log_damage(player, 940)

    result = statistics.to_hash

    expect(result[:participants].find { |row| row[:id] == player.id }).to include(
      physical_damage: 605, total_damage: 605, opponents_defeated: 1, total_hits: 2, xp_earned: 57, is_alive: false
    )
    expect(result[:participants].find { |row| row[:id] == npc.id }).to include(
      total_damage: 0, opponents_defeated: 0, total_hits: 0, xp_earned: 0
    )
    expect(result[:total_damage]).to eq(605)
    expect(result[:teams]["a"]).to include(total_damage: 605, physical_damage: 605, opponents_defeated: 1, total_hits: 2, xp_earned: 57)
    expect(result[:teams]["b"]).to include(total_damage: 0, xp_earned: 0)
    expect(match.combat_log_entries.sum(:damage_amount)).to eq(1626)
    expect(player.reload.metadata).to include("damage_dealt" => 605, "raw_damage_dealt" => 686, "damage_hits" => 1)
  end

  it "keeps a defeated participant in historical statistics after the character recovers HP" do
    log_damage(player, 686)
    character.update!(current_hp: 1)

    row = statistics.by_participant.find { |entry| entry[:id] == player.id }

    expect(character.reload.current_hp).to be_positive
    expect(row).to include(is_alive: false, visible: true, total_damage: 605, opponents_defeated: 1, xp_earned: 57)
    expect(statistics.by_team["a"]).to include(members: 1, alive: 0, total_damage: 605, xp_earned: 57)
    expect(player.reload).to be_defeat
    expect(match.combat_log_entries.where(actor: player).count).to eq(1)
  end

  it "preserves raw event damage in body-part and round diagnostics" do
    log_damage(player, 686)
    log_damage(player, 940, round_number: 2)

    expect(statistics.body_part_breakdown["torso"]).to eq(attacks: 2, damage: 1626, blocked: 0)
    expect(statistics.round_summary).to eq([
      {round: 1, total_damage: 686, events: 1},
      {round: 2, total_damage: 940, events: 1}
    ])
    expect(statistics.total_damage).to eq(605)
  end

  it "does not turn multiple nonlethal hits into defeated opponents" do
    player.update!(metadata: {"damage_dealt" => 100, "opponents_defeated" => 0, "damage_hits" => 2})
    log_damage(player, 40)
    log_damage(player, 60)

    expect(statistics.by_participant.find { |row| row[:id] == player.id }).to include(
      physical_damage: 100, total_damage: 100, opponents_defeated: 0, total_hits: 2
    )
  end

  it "honors explicit zero damage rather than falling back to damaging log events" do
    player.update!(metadata: {"damage_dealt" => 0, "opponents_defeated" => 0})
    log_damage(player, 940)

    expect(statistics.by_participant.find { |row| row[:id] == player.id }).to include(total_damage: 0, total_hits: 1)
    expect(statistics.total_damage).to eq(0)
  end

  it "retains zero credited damage for a finalized simultaneous strike after its target was defeated" do
    player.update!(metadata: {"experience_awarded" => 1})
    match.update!(metadata: match.metadata.merge("rewards_processed_at" => Time.current.iso8601))
    log_damage(player, 70)

    expect(statistics.by_participant.find { |row| row[:id] == player.id }).to include(
      physical_damage: 0, total_damage: 0, opponents_defeated: 0, total_hits: 1, xp_earned: 1
    )
    expect(statistics.total_damage).to eq(0)
    expect(statistics.round_summary.first[:total_damage]).to eq(70)
  end

  it "keeps identical NPC names distinct by participation identity" do
    other_npc = create(:arena_participation, :npc, arena_match: match, npc_template: npc.npc_template,
      team: "b", metadata: {"current_hp" => 40, "max_hp" => 100, "damage_dealt" => 25, "opponents_defeated" => 1})
    npc.update!(metadata: npc.metadata.merge("damage_dealt" => 5))
    log_damage(npc, 5, target: player)
    log_damage(other_npc, 25, target: player)
    log_damage(other_npc, 900, target: player)

    rows = statistics.by_participant.select { |row| row[:team] == "b" }
    expect(rows.map { |row| row[:name] }.uniq).to eq([npc.participant_name])
    expect(rows.index_by { |row| row[:id] }.transform_values { |row| row[:total_damage] }).to eq(npc.id => 5, other_npc.id => 25)
    expect(statistics.by_team["b"]).to include(members: 2, alive: 1, physical_damage: 30, total_damage: 30, opponents_defeated: 1, total_hits: 3)
  end

  it "falls back to legacy log sums and Character actors without inventing defeat counts or XP" do
    player.update!(metadata: {"combat_profile" => {"action_points" => 100}})
    npc.update!(metadata: {"current_hp" => 0, "max_hp" => 605})
    match.update!(metadata: {"encounter_experience_reward" => 999})
    log_damage(player, 686)
    log_damage(character, 940)
    log_damage(npc, 5, target: player)
    log_damage(nil, 7, target: player)

    expect(statistics.by_participant.find { |row| row[:id] == player.id }).to include(
      physical_damage: 1626, total_damage: 1626, opponents_defeated: nil, total_hits: 2, xp_earned: 0
    )
    expect(statistics.by_team["a"]).to include(total_damage: 1626, opponents_defeated: nil, total_hits: 2)
    expect(statistics.total_damage).to eq(1638)
  end

  it "uses per-participant fallback when credited and older rows coexist" do
    npc.update!(metadata: {"current_hp" => 0, "max_hp" => 605})
    log_damage(player, 686)
    log_damage(npc, 17, target: player)

    expect(statistics.by_team["a"][:total_damage]).to eq(605)
    expect(statistics.by_team["b"][:total_damage]).to eq(17)
    expect(statistics.total_damage).to eq(622)
  end

  it "attributes actual awarded XP by character id rather than team, names or configured rewards" do
    winner = create(:arena_participation, :victory, arena_match: match, team: "b")
    match.update!(metadata: {
      "encounter_experience_reward" => 9000,
      "rewards" => {"experience" => {"character_id" => winner.character_id, "amount" => 12}}
    })

    expect(statistics.by_participant.find { |row| row[:id] == player.id }[:xp_earned]).to eq(0)
    expect(statistics.by_participant.find { |row| row[:id] == winner.id }[:xp_earned]).to eq(12)
    expect(statistics.by_participant.find { |row| row[:id] == npc.id }[:xp_earned]).to eq(0)
  end

  it "retains empty historical statistics" do
    empty_match = create(:arena_match, :completed)

    expect(described_class.new(empty_match).to_hash).to include(total_damage: 0, participants: [], teams: {})
  end

  it "uses two grouped log queries for participant, team and overall aggregates regardless of roster size" do
    player.update!(metadata: {})
    log_damage(player, 686)
    create_list(:arena_participation, 8, :npc, arena_match: match, npc_template: npc.npc_template, team: "b")
    queries = []
    subscriber = lambda do |*args|
      payload = args.last
      queries << payload[:sql] if payload[:sql].match?(/SELECT.*combat_log_entries/i)
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      statistics.by_participant
      statistics.by_team
      statistics.total_damage
    end

    expect(statistics.by_participant.size).to eq(10)
    expect(queries.size).to eq(2)
    expect(queries).to all(include("GROUP BY"))
    expect(queries).to all(satisfy { |sql| !sql.match?(/ORDER BY/i) })
  end
end
