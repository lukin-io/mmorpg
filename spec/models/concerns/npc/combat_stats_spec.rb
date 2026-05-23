# frozen_string_literal: true

require "rails_helper"

RSpec.describe Npc::CombatStats do
  let(:npc_template) { create(:npc_template, level: 10, role: "hostile") }

  describe "#combat_stats" do
    it "does not invent stats from level" do
      expect(npc_template.combat_stats).to include(
        attack: 0,
        defense: 0,
        agility: 0,
        hp: 0,
        crit_chance: 0,
        dodge_chance: 0
      )
    end

    it "uses explicit metadata stats before formulas" do
      npc_template.update!(metadata: {"stats" => {"attack" => 12, "defense" => 8, "hp" => 44}})

      expect(npc_template.combat_stats).to include(attack: 12, defense: 8, hp: 44)
    end

    it "does not apply generic role modifiers" do
      arena_bot = create(:npc_template, level: 10, role: "arena_bot")

      expect(arena_bot.combat_stats).to include(
        attack: 0,
        defense: 0,
        hp: 0
      )
    end

    it "ignores level overrides unless source stats are captured" do
      expect(npc_template.combat_stats(override_level: 5)).to include(
        attack: 0,
        hp: 0
      )
    end
  end

  describe "convenience accessors" do
    it "returns individual combat stats" do
      npc_template.update!(metadata: {"stats" => {"attack" => 12, "defense" => 8, "hp" => 44}})

      expect(npc_template.combat_stat(:attack)).to eq(12)
      expect(npc_template.max_hp).to eq(44)
      expect(npc_template.attack_power).to eq(12)
      expect(npc_template.defense_value).to eq(8)
    end

    it "returns an attack damage range with minimum variance" do
      weak_npc = create(:npc_template, level: 1, role: "hostile", metadata: {"base_damage" => 2})

      expect(weak_npc.attack_damage_range).to eq(1..3)
    end

    it "returns a zero damage range when no source attack was captured" do
      expect(npc_template.attack_damage_range).to eq(0..0)
    end
  end
end
