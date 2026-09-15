# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArenaParticipation, type: :model do
  it "keeps recorded player and NPC defeat terminal despite later resource recovery" do
    match = create(:arena_match, status: :live)
    fallen = create(:arena_participation, arena_match: match, team: "a", result: :defeat)
    fallen.character.update!(current_hp: 100)
    npc = create(:arena_participation, :npc, arena_match: match, team: "a", result: :defeat,
      metadata: {"current_hp" => 100, "max_hp" => 100})
    survivor = create(:arena_participation, arena_match: match, team: "b")
    survivor.character.update!(current_hp: 100)

    expect(fallen).not_to be_combat_alive
    expect(npc).not_to be_combat_alive
    expect(survivor).to be_combat_alive
    expect(match.should_auto_end_defeat?).to be true
    expect(match.determine_winner).to eq("b")
    expect(Arena::CombatProcessor.new(match).determine_winner).to eq("b")
  end

  describe "NPC combat content" do
    it "uses complete per-level and per-member equipment sets, including an explicitly empty set" do
      npc = create(:npc_template, metadata: {
        "equipment" => {"main_hand" => {"name" => "Club"}, "chest" => {"name" => "Armor"}},
        "level_profiles" => {"1" => {"equipment" => {"main_hand" => {"name" => "Stick"}}}}
      })
      lower = create(:arena_participation, :npc, npc_template: npc, metadata: {"level" => 1})
      empty = create(:arena_participation, :npc, npc_template: npc, metadata: {"level" => 1, "equipment" => {}})
      [lower, empty].each(&:snapshot_npc_combat_data!)

      expect(lower.reload.npc_combat_data["equipment"]).to eq("main_hand" => {"name" => "Stick"})
      expect(empty.reload.npc_combat_data["equipment"]).to eq({})
      npc.update!(metadata: {})
      expect(lower.reload.npc_combat_data.dig("equipment", "main_hand", "name")).to eq("Stick")
    end

    it "selects an explicit level setup before applying a member override" do
      npc = create(:npc_template, level: 9, metadata: {
        "max_mp" => 7,
        "level_profiles" => {
          "7" => {"display_stats" => {"strength" => 20, "armor_class" => 10}, "stats" => {"attack" => 3}},
          "9" => {"display_stats" => {"strength" => 24, "armor_class" => 20}, "stats" => {"attack" => 5}}
        }
      })
      participation = create(:arena_participation, :npc, npc_template: npc,
        metadata: {"level" => 7, "display_stats" => {"armor_class" => 11}})
      participation.snapshot_npc_combat_data!

      expect(participation.reload.npc_combat_data["display_stats"]).to eq("strength" => 20, "armor_class" => 11)
      expect(participation.combat_stats[:attack]).to eq(3)
      expect(participation.max_mp).to eq(7)
    end

    it "freezes template content with independent member overrides when a fight starts" do
      npc = create(:npc_template, metadata: {
        "stats" => {"attack" => 17}, "display_stats" => {"strength" => 17}, "max_mp" => 7,
        "avatar_image" => "orc.png", "equipment" => {"main_hand" => {"name" => "Orc Dagger", "artwork" => "orc_dagger"}},
        "combat_profile" => {"physical_attack_cost_seed" => 62}
      })
      first = create(:arena_participation, :npc, npc_template: npc)
      second = create(:arena_participation, :npc, npc_template: npc,
        metadata: {"stats" => {"attack" => 24}, "display_stats" => {"strength" => 24}})
      [first, second].each(&:snapshot_npc_combat_data!)
      npc.update!(metadata: {"stats" => {"attack" => 999}, "avatar_image" => "skeleton.png"})

      expect(first.reload.combat_stats[:attack]).to eq(17)
      expect(second.reload.combat_stats[:attack]).to eq(24)
      expect(first.npc_combat_data).to include("max_mp" => 7, "avatar_image" => "orc.png")
      expect(first.npc_combat_data.dig("equipment", "main_hand", "name")).to eq("Orc Dagger")
      expect(Arena::CombatProfile.for_participation(first)["simple_attack_cost"]).to eq(62)
      first.snapshot_npc_combat_data!
      expect(first.reload.combat_stats[:attack]).to eq(17)
    end

    it "rejects malformed roster content before a participation is persisted" do
      npc_template = create(:npc_template)
      [{"display_stats" => {"strength" => "unknown"}},
        {"equipment" => {"invented_slot" => {"name" => "Knife"}}},
        {"npc_combat_data" => []}, {"avatar_image" => "../../private.png"}].each do |metadata|
        participation = build(:arena_participation, :npc, npc_template:, metadata:)
        expect(participation).not_to be_valid
        expect(participation.errors[:metadata]).to be_present
      end
    end
  end

  describe "player effective maxima" do
    it "uses current equipment bonuses without changing base or current vitals" do
      character = create(:character, max_hp: 100, current_hp: 80, max_mp: 50, current_mp: 30)
      participation = create(:arena_participation, character:, user: character.user)
      template = create(:item_template, stat_modifiers: {"hp" => 60, "mana" => 25})
      item = create(:inventory_item, :equipped, inventory: character.inventory, item_template: template)

      expect(participation.reload.max_hp).to eq(160)
      expect(participation.max_mp).to eq(75)
      expect(participation.current_hp).to eq(80)
      expect(participation.current_mp).to eq(30)
      expect(character.reload.max_hp).to eq(100)
      expect(character.max_mp).to eq(50)

      item.update!(equipped: false, equipment_slot: nil)

      expect(participation.reload.max_hp).to eq(100)
      expect(participation.max_mp).to eq(50)
      expect(participation.current_hp).to eq(80)
      expect(participation.current_mp).to eq(30)
    end

    it "ignores broken equipment and preserves zero base mana" do
      character = create(:character, max_mp: 0, current_mp: 0)
      participation = create(:arena_participation, character:, user: character.user)
      template = create(:item_template, :durable, stat_modifiers: {"max_hp" => 60, "max_mp" => 25})
      create(:inventory_item, :equipped, :broken, inventory: character.inventory, item_template: template)

      expect(participation.max_hp).to eq(100)
      expect(participation.max_mp).to eq(0)
      expect(participation.current_mp).to eq(0)
    end
  end

  describe "#participant_level" do
    it "uses a positive captured level override for a sampled NPC" do
      participation = create(:arena_participation, :sampled_npc)

      expect(participation.participant_level).to eq(8)
    end

    it "falls back to the NPC template for a missing or invalid override" do
      template = create(:npc_template, level: 7)

      [nil, "unknown", -1, 0.5].each do |level|
        participation = create(
          :arena_participation,
          :npc,
          npc_template: template,
          metadata: {"current_hp" => 155, "max_hp" => 155, "level" => level}
        )

        expect(participation.participant_level).to eq(7)
      end
    end

    it "preserves a level-zero member override over a higher-level template" do
      template = create(:npc_template, level: 7)
      participation = create(:arena_participation, :npc, npc_template: template,
        metadata: {"current_hp" => 40, "max_hp" => 40, "level" => 0})

      expect(participation.reload.participant_level).to eq(0)
    end

    it "keeps player level authoritative on the character" do
      character = build(:character, level: 12)
      participation = build(:arena_participation, character:, metadata: {"level" => 99})

      expect(participation.participant_level).to eq(12)
    end
  end
end
