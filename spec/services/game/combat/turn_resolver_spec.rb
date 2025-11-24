require "rails_helper"
require "ostruct"

RSpec.describe Game::Combat::TurnResolver do
  let(:attacker_stats) do
    Game::Systems::StatBlock.new(base: {attack: 12, crit_chance: 50, initiative: 15}, mods: {})
  end

  let(:defender_stats) do
    Game::Systems::StatBlock.new(base: {defense: 4, luck: 10, initiative: 5}, mods: {})
  end

  let(:attacker) { OpenStruct.new(name: "Warrior", stats: attacker_stats) }
  let(:defender) { OpenStruct.new(name: "Wolf", stats: defender_stats) }
  let(:battle) { create(:battle) }

  it "produces deterministic damage with seeded RNG and persists logs" do
    result = described_class.new(
      attacker: attacker,
      defender: defender,
      action: "Slash",
      rng: Random.new(1),
      battle:
    ).call

    expect(result.hp_changes[:defender]).to be_negative
    expect(result.log.first).to include("Slash")
    expect(battle.combat_log_entries.count).to eq(1)
  end

  context "with battle participants and ability effects" do
    let(:attacking_character) { create(:character, :with_position) }
    let(:defending_character) { create(:character, :with_position) }
    let(:battle) { create(:battle, battle_type: :pvp, initiator: attacking_character, pvp_mode: "duel") }
    let!(:attacker_participant) { create(:battle_participant, battle:, character: attacking_character, team: "alpha", initiative: 15) }
    let!(:defender_participant) { create(:battle_participant, battle:, character: defending_character, team: "bravo", initiative: 5) }
    let(:ability) do
      create(
        :ability,
        character_class: attacking_character.character_class,
        effects: {
          "status" => "shield",
          "buffs" => [{"name" => "Fury", "duration" => 2, "stat_changes" => {"attack" => 3}}],
          "debuffs" => [{"name" => "Expose", "duration" => 2, "stat_changes" => {"defense" => -2}}],
          "damage" => 5
        }
      )
    end

    it "applies buffs/debuffs and records attacker metadata" do
      result = described_class.new(
        attacker: attacking_character,
        defender: defending_character,
        action: ability.name,
        rng: Random.new(3),
        battle:,
        ability:
      ).call

      expect(result.effects[:buffs].first["name"]).to eq("Fury")
      log_payload = battle.combat_log_entries.last.payload
      expect(log_payload["attacker_id"]).to eq(attacking_character.id)
      expect(attacker_participant.reload.buffs["active"].first["name"]).to eq("Fury")
    end
  end
end
