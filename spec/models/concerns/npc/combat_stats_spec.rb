# frozen_string_literal: true

require "rails_helper"

RSpec.describe Npc::CombatStats do
  let(:npc_template) { create(:npc_template, level: 10, role: "hostile") }

  describe "#combat_stats" do
    it "calculates default stats from level" do
      expect(npc_template.combat_stats).to include(
        attack: 35,
        defense: 23,
        agility: 15,
        hp: 120,
        crit_chance: 10,
        dodge_chance: 5
      )
    end

    it "uses explicit metadata stats before formulas" do
      npc_template.update!(metadata: {"stats" => {"attack" => 12, "defense" => 8, "hp" => 44}})

      expect(npc_template.combat_stats).to include(attack: 12, defense: 8, hp: 44)
    end

    it "applies the arena bot modifier" do
      arena_bot = create(:npc_template, level: 10, role: "arena_bot")

      expect(arena_bot.combat_stats).to include(
        attack: 31,
        defense: 20,
        hp: 114
      )
    end

    it "supports level overrides" do
      expect(npc_template.combat_stats(override_level: 5)).to include(
        attack: 20,
        hp: 70
      )
    end
  end

  describe "convenience accessors" do
    it "returns individual combat stats" do
      expect(npc_template.combat_stat(:attack)).to eq(35)
      expect(npc_template.max_hp).to eq(120)
      expect(npc_template.attack_power).to eq(35)
      expect(npc_template.defense_value).to eq(23)
    end

    it "returns an attack damage range with minimum variance" do
      weak_npc = create(:npc_template, level: 1, role: "hostile", metadata: {"base_damage" => 2})

      expect(weak_npc.attack_damage_range).to eq(1..3)
    end
  end
end
