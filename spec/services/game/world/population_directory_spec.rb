# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::World::PopulationDirectory do
  subject(:directory) { described_class.instance }

  describe "#npc" do
    it "wraps npc configuration with helper behavior" do
      npc = directory.npc("magistrate_serra")

      expect(npc).to be_present
      expect(npc.roles).to include("quest_giver")
      expect(npc.reaction_for(reputation: 50)).to eq(:friendly)
    end
  end

  describe "#spawn_entries_for" do
    it "returns monster spawn definitions merged from yaml" do
      entries = directory.spawn_entries_for("ashen_forest")

      expect(entries).not_to be_empty
      expect(entries.first).to include("rarity")
    end

    it "uses NPC template spawn timing instead of admin schedule overrides" do
      create(
        :npc_template,
        npc_key: "forest_wolf",
        name: "Forest Wolf Template",
        metadata: {
          "rarity" => "rare",
          "spawn_chance" => 9,
          "respawn_seconds" => 7200
        }
      )

      entry = directory.spawn_entries_for("ashen_forest").find { |spawn| spawn["monster_key"] == "forest_wolf" }

      expect(entry).to include(
        "name" => "Forest Wolf Template",
        "rarity" => "rare",
        "weight" => 9,
        "respawn_seconds" => 7200
      )
    end
  end
end
